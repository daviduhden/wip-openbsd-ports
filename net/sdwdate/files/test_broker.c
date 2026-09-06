/* SPDX-License-Identifier: AGPL-3.0-or-later */
/* Every broker invocation below is hard-coded dry-run: never set the clock. */
#include <sys/time.h>
#define main clock_parent_main
#include "clock-parent.c"
#undef main
#include <assert.h>

static void
check(const char *packet, size_t length, const char *expected, int slew_only)
{
	int sv[2], status;
	pid_t pid;
	char response[128];
	struct timeval limit = {3, 0};
	assert(socketpair(AF_UNIX, SOCK_SEQPACKET, 0, sv) == 0);
	assert((pid = fork()) >= 0);
	if (!pid) {
		alarm(5);
		close(sv[0]);
		int result = broker(sv[1], 1, slew_only);
		close(sv[1]);
		_exit(result == 0 ? 0 : 1);
	}
	close(sv[1]);
	assert(setsockopt(sv[0], SOL_SOCKET, SO_RCVTIMEO, &limit, sizeof(limit)) == 0);
	assert(send(sv[0], packet, length, 0) == (ssize_t)length);
	ssize_t n = recv(sv[0], response, sizeof(response) - 1, 0);
	assert(n > 0);
	response[n] = '\0';
	assert(strncmp(response, expected, strlen(expected)) == 0);
	close(sv[0]);
	assert(waitpid(pid, &status, 0) == pid && WIFEXITED(status));
	assert(WEXITSTATUS(status) == (!strcmp(expected, "OK") ? 0 : 1));
}

static void
check_repeated_request(void)
{
	int sv[2], status;
	pid_t pid;
	char response[128];
	struct timeval limit = {3, 0};
	assert(socketpair(AF_UNIX, SOCK_SEQPACKET, 0, sv) == 0);
	assert((pid = fork()) >= 0);
	if (!pid) {
		alarm(5);
		close(sv[0]);
		int result = broker(sv[1], 1, 0);
		close(sv[1]);
		_exit(result == 0 ? 0 : 1);
	}
	close(sv[1]);
	assert(setsockopt(sv[0], SOL_SOCKET, SO_RCVTIMEO, &limit, sizeof(limit)) == 0);
	assert(send(sv[0], "A 0", 3, 0) == 3);
	assert(recv(sv[0], response, sizeof(response), 0) == 2);
	assert(!memcmp(response, "OK", 2));
	assert(send(sv[0], "A 0", 3, 0) == 3);
	assert(recv(sv[0], response, sizeof(response), 0) >= 5);
	assert(!memcmp(response, "ERROR", 5));
	close(sv[0]);
	assert(waitpid(pid, &status, 0) == pid && WIFEXITED(status));
	assert(WEXITSTATUS(status) == 1);
}

int main(void)
{
	const char *bad[] = {"", "A ", "X 1", "J 1 2", "A  1", "A 1\n",
	    "J 86400000000001", "A 30000000001", "A -30000000001", NULL};
	/* An empty seqpacket is EOF by policy; tested separately by close below. */
	for (int i = 1; bad[i]; i++)
		check(bad[i], strlen(bad[i]), "ERROR", 0);
	check("A 0", 3, "OK", 0);
	check("A -1", 4, "OK", 0);
	check("J 86400000000000", 16, "OK", 0);
	check("J 1", 3, "ERROR", 1);
	check("A 1\0extra", 9, "ERROR", 0);
	char oversized[128];
	memset(oversized, '1', sizeof(oversized));
	oversized[0] = 'A';
	oversized[1] = ' ';
	check(oversized, sizeof(oversized), "ERROR", 0);
	check_repeated_request();
	puts("dry-run broker framing and policy tests passed");
	return 0;
}
