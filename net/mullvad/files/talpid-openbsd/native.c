/* SPDX-License-Identifier: GPL-3.0-or-later */
/* OpenBSD ABI glue. No Linux compatibility definitions or shell commands.
 * RTM_PROPOSAL layout follows the documented route(8) nameserver protocol.
 * These low-level primitives are not an integrated DNS/route/VPN policy.
 */
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <sys/uio.h>
#include <net/if.h>
#include <net/route.h>
#include <netinet/in.h>
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int
mv_route_monitor(void)
{
	int fd, saved;
	unsigned int table = 0;
	/* Readable by poll/kqueue; subscribe before taking a route snapshot. */
	fd = socket(AF_ROUTE, SOCK_RAW | SOCK_CLOEXEC | SOCK_NONBLOCK, AF_UNSPEC);
	if (fd == -1)
		return -1;
	if (setsockopt(fd, AF_ROUTE, ROUTE_TABLEFILTER, &table, sizeof(table)) == -1) {
		saved = errno;
		close(fd);
		errno = saved;
		return -1;
	}
	return fd;
}

static int
proposal(int fd, unsigned int index, int family, const uint8_t *addresses,
    size_t count, int sequence)
{
	struct rt_msghdr hdr;
	struct sockaddr_rtdns dns;
	struct iovec vec[3];
	long padding = 0;
	size_t size, aligned;
	ssize_t sent;

	memset(&hdr, 0, sizeof(hdr));
	memset(&dns, 0, sizeof(dns));
	size = family == AF_INET ? sizeof(struct in_addr) : sizeof(struct in6_addr);
	if (count > 5 || count * size > sizeof(dns.sr_dns)) {
		errno = EINVAL;
		return -1;
	}
	dns.sr_family = family;
	dns.sr_len = offsetof(struct sockaddr_rtdns, sr_dns) + count * size;
	if (count != 0)
		memcpy(dns.sr_dns, addresses, count * size);
	aligned = (sizeof(dns) + sizeof(long) - 1) & ~(sizeof(long) - 1);
	hdr.rtm_msglen = sizeof(hdr) + aligned;
	hdr.rtm_version = RTM_VERSION;
	hdr.rtm_type = RTM_PROPOSAL;
	hdr.rtm_hdrlen = sizeof(hdr);
	hdr.rtm_index = index;
	hdr.rtm_priority = RTP_PROPOSAL_STATIC;
	hdr.rtm_addrs = RTA_DNS;
	hdr.rtm_flags = RTF_UP;
	hdr.rtm_pid = getpid();
	hdr.rtm_seq = sequence;
	vec[0] = (struct iovec){ &hdr, sizeof(hdr) };
	vec[1] = (struct iovec){ &dns, sizeof(dns) };
	vec[2] = (struct iovec){ &padding, aligned - sizeof(dns) };
	do {
		sent = writev(fd, vec, 3);
	} while (sent == -1 && errno == EINTR);
	if (sent == -1)
		return -1;
	if ((size_t)sent != hdr.rtm_msglen) {
		errno = EIO;
		return -1;
	}
	return 0;
}

/* Always send BOTH families, including empty withdrawals. A caller must
 * maintain the firewall block until resolver state is independently verified.
 * RTM_PROPOSAL has no resolvd acknowledgement and no two-message transaction.
 */
int
mv_dns_propose(const char *name, const uint8_t *v4, size_t n4,
    const uint8_t *v6, size_t n6)
{
	unsigned int index;
	int fd, saved, result = 0;
	if (n4 > 5 || n6 > 5 || n4 + n6 > 5) {
		errno = EINVAL;
		return -1;
	}
	index = if_nametoindex(name);
	if (index == 0) {
		errno = ENXIO;
		return -1;
	}
	fd = socket(AF_ROUTE, SOCK_RAW | SOCK_CLOEXEC, AF_UNSPEC);
	if (fd == -1)
		return -1;
	saved = 0;
	if (proposal(fd, index, AF_INET, v4, n4, 1) == -1) {
		result = -1;
		saved = errno;
	}
	if (proposal(fd, index, AF_INET6, v6, n6, 2) == -1) {
		result = -1;
		if (saved == 0)
			saved = errno;
	}
	close(fd);
	errno = saved;
	return result;
}

/* Read-only native routing-table dump. The caller owns the returned buffer
 * and must free it with mv_route_snapshot_free. Consumers must validate every
 * variable-length message before using it; no Darwin struct layouts apply.
 * Route mutation/ownership and crash-recovery journaling are not implemented.
 */
int
mv_route_snapshot(uint8_t **data, size_t *length)
{
	int mib[] = { CTL_NET, PF_ROUTE, 0, AF_UNSPEC, NET_RT_DUMP, 0, 0 };
	size_t size;
	uint8_t *buffer;
	int attempt, saved;
	*data = NULL;
	*length = 0;
	for (attempt = 0; attempt < 3; attempt++) {
		if (sysctl(mib, 7, NULL, &size, NULL, 0) == -1)
			return -1;
		if (size == 0)
			return 0;
		buffer = malloc(size);
		if (buffer == NULL)
			return -1;
		if (sysctl(mib, 7, buffer, &size, NULL, 0) == 0) {
			*data = buffer;
			*length = size;
			return 0;
		}
		saved = errno;
		free(buffer);
		if (saved != ENOMEM) {
			errno = saved;
			return -1;
		}
	}
	errno = EAGAIN;
	return -1;
}

void
mv_route_snapshot_free(uint8_t *data)
{
	free(data);
}
