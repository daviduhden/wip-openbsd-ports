COMMENT =	hardware probe tool
CATEGORIES =	sysutils

GH_ACCOUNT =	linuxhw
GH_PROJECT =	hw-probe
GH_TAGNAME =	1.6.6

MAINTAINER =	David Uhden Collado <daviduhden@gmail.com>

# BSD-4 or LGPLv2.1+
PERMIT_PACKAGE =	Yes

RUN_DEPENDS =	net/curl \
		sysutils/lscpu \
		sysutils/pciutils \
		sysutils/smartmontools \
		sysutils/usbutil \
		sysutils/usbutils \
		www/p5-Test-LWP-UserAgent

.if ${MACHINE_ARCH} == "amd64" || ${MACHINE_ARCH} == "i386"
RUN_DEPENDS +=	sysutils/dmidecode
.endif

FAKE_FLAGS =	prefix=${PREFIX} tool_dir=${DESTDIR}${PREFIX}/sbin

NO_BUILD =	Yes
NO_TEST =	Yes

.include <bsd.port.mk>
