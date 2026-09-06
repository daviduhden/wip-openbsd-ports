/* SPDX-License-Identifier: AGPL-3.0-or-later */
/* OpenBSD clock broker: no public socket and no setuid executable. */
#include <sys/types.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
#include <poll.h>
#include <pwd.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SCLOCKADJ_LIBRARY
#include "sclockadj.c"

static volatile sig_atomic_t stopping;

static void
stop(int sig)
{
	(void)sig;
	stopping = 1;
}

static int
reply(int fd, const char *msg)
{
	size_t len = strlen(msg);
	return send(fd, msg, len, 0) == (ssize_t)len ? 0 : -1;
}

static int
broker(int fd, int dry, int slew_only)
{
	struct pollfd pfd = {fd, POLLIN, 0};
	struct timespec now, last = {0, 0}, tick = {0, 0};
	int64_t remaining = 0;
	int first = 1;
	char buf[64];

	while (!stopping) {
		int r = poll(&pfd, 1, remaining ? 100 : 1000);
		if (r < 0) {
			if (errno == EINTR)
				continue;
			return -1;
		}
		if (pfd.revents & (POLLERR | POLLNVAL))
			return -1;
		if (pfd.revents & POLLHUP)
			return 0;
		if (clock_gettime(CLOCK_MONOTONIC, &now) == -1)
			return -1;
		if (pfd.revents & POLLIN) {
			int64_t offset;
			ssize_t n = recv(fd, buf, sizeof(buf) - 1, 0);
			if (n == 0)
				return 0;
			if (n < 0)
				return -1;
			buf[n] = '\0';
			/* SOCK_SEQPACKET preserves boundaries; reject truncation,
			 * embedded NULs and extra fields. No request is queued. */
			if (n >= (ssize_t)sizeof(buf) - 1 ||
			    strlen(buf) != (size_t)n || n < 3 || buf[1] != ' ' ||
			    (buf[0] != 'A' && buf[0] != 'J') ||
			    parse_offset(buf + 2, &offset) == -1 || remaining ||
			    (!first && now.tv_sec - last.tv_sec < 60) ||
			    (buf[0] == 'J' && (!first || slew_only)) ||
			    (buf[0] == 'A' && (offset > 30 * NS || offset < -30 * NS))) {
				reply(fd, "ERROR invalid or disallowed correction");
				return -1;
			}
			first = 0;
			last = tick = now;
			if (dry || offset == 0) {
				if (reply(fd, "OK") == -1)
					return -1;
			} else if (buf[0] == 'J') {
				if (change_time_by_nanoseconds(offset) == -1) {
					reply(fd, "ERROR clock_settime");
					return -1;
				}
				if (reply(fd, "OK") == -1)
					return -1;
			} else {
				remaining = offset;
			}
		}
		if (remaining && (now.tv_sec > tick.tv_sec + 1 ||
		    (now.tv_sec == tick.tv_sec + 1 && now.tv_nsec >= tick.tv_nsec))) {
			int64_t step = remaining > STEP ? STEP :
			    remaining < -STEP ? -STEP : remaining;
			/* Never catch up with a burst after scheduling delays. */
			if (change_time_by_nanoseconds(step) == -1) {
				reply(fd, "ERROR clock_settime");
				return -1;
			}
			remaining -= step;
			tick = now;
			if (!remaining && reply(fd, "OK") == -1)
				return -1;
		}
	}
	return 0;
}

int
main(int argc, char **argv)
{
	struct passwd *pw;
	struct group *gr;
	struct stat st;
	struct sigaction sa;
	int sv[2], lockfd, dry = 0, slew_only = 0, once = 0, result, status;
	int startup_failed = 0;
	pid_t child;
	uid_t uid;
	gid_t gid, groups[2];
	char *args[] = {"${MODPY_BIN}", "-sBP", "-m", "sdwdate.openbsd",
	    "--broker", NULL, NULL, NULL, NULL};
	char *env[] = {"PATH=${LOCALBASE}/bin:/usr/bin:/bin",
	    "PYTHONPATH=${TRUEPREFIX}/libexec/sdwdate", "HOME=/var/db/sdwdate",
	    "LANG=C.UTF-8", "TZ=UTC", NULL};
	int ai = 5;

	for (int i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "--dry-run"))
			dry = 1;
		else if (!strcmp(argv[i], "--slew-only"))
			slew_only = 1;
		else if (!strcmp(argv[i], "--once"))
			once = 1;
		else {
			fprintf(stderr, "usage: sdwdate [--dry-run] [--slew-only] [--once]\n");
			return 1;
		}
	}
	if (geteuid() != 0 || getuid() != 0) {
		fprintf(stderr, "sdwdate: start the broker as root (not setuid)\n");
		return 1;
	}
	closefrom(3);
	if ((pw = getpwnam("_sdwdate")) == NULL || pw->pw_uid == 0)
		return 1;
	uid = pw->pw_uid;
	gid = pw->pw_gid;
	if ((gr = getgrnam("_tor")) == NULL)
		return 1;
	groups[0] = gid;
	groups[1] = gr->gr_gid;
	umask(077);
	lockfd = open("/var/run/sdwdate.lock", O_CREAT | O_RDWR | O_NOFOLLOW, 0600);
	if (lockfd == -1 || fstat(lockfd, &st) == -1 || !S_ISREG(st.st_mode) ||
	    st.st_uid != 0 || st.st_nlink != 1 || (st.st_mode & 077) ||
	    flock(lockfd, LOCK_EX | LOCK_NB) == -1) {
		perror("sdwdate: lock");
		return 1;
	}
	if (socketpair(AF_UNIX, SOCK_SEQPACKET, 0, sv) == -1)
		return 1;
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = stop;
	sigemptyset(&sa.sa_mask);
	if (sigaction(SIGTERM, &sa, NULL) == -1 ||
	    sigaction(SIGINT, &sa, NULL) == -1)
		return 1;
	signal(SIGPIPE, SIG_IGN);
	if ((child = fork()) == -1)
		return 1;
	if (child == 0) {
		if (setpgid(0, 0) == -1)
			_exit(1);
		close(lockfd);
		close(sv[0]);
		if (sv[1] != 3 && dup2(sv[1], 3) == -1)
			_exit(1);
		closefrom(4);
		if (setgroups(2, groups) == -1 || setresgid(gid, gid, gid) == -1 ||
		    setresuid(uid, uid, uid) == -1 || chdir("/var/db/sdwdate") == -1)
			_exit(1);
		if (dry)
			args[ai++] = "--dry-run";
		if (slew_only)
			args[ai++] = "--slew-only";
		if (once)
			args[ai++] = "--once";
		execve(args[0], args, env);
		_exit(1);
	}
	close(sv[1]);
	/* The child also sets its group before exec, closing the shutdown race. */
	if (setpgid(child, child) == -1 && errno != EACCES)
		startup_failed = stopping = 1;
	/* No filesystem access, network socket, exec, or loaded Python in parent.
	 * pledge cannot allow clock_settime: do not promise unsupported settime. */
	if (chroot("/var/empty") == -1 || chdir("/") == -1)
		startup_failed = stopping = 1;
#ifdef __OpenBSD__
	if (unveil("/", "r") == -1 || unveil(NULL, NULL) == -1)
		startup_failed = stopping = 1;
#endif
	result = broker(sv[0], dry, slew_only);
	close(sv[0]);
	/* EOF cancels all incremental corrections. Never leave a pending slew. */
	kill(-child, SIGTERM);
	for (int i = 0; i < 30; i++) {
		pid_t w = waitpid(child, &status, WNOHANG);
		if (w == child)
			return startup_failed ? 1 : stopping ? 0 :
			    result == 0 && WIFEXITED(status) && WEXITSTATUS(status) == 0 ? 0 : 1;
		if (w == -1 && errno != EINTR)
			break;
		struct timespec delay = {0, 100000000};
		nanosleep(&delay, NULL);
	}
	kill(-child, SIGKILL);
	while (waitpid(child, &status, 0) == -1 && errno == EINTR)
		;
	return startup_failed ? 1 : stopping ? 0 : 1;
}
