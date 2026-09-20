COMMENT =		execute a command as another user (memory-safe implementation)

V =			0.2.15
DISTNAME =		sudo-rs-${V}
GH_ACCOUNT =		trifectatechfoundation
GH_PROJECT =		sudo-rs
GH_TAGNAME =		v${V}
CATEGORIES =		security

HOMEPAGE =		https://github.com/trifectatechfoundation/sudo-rs/

# Apache 2.0 OR MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		${MODCARGO_WANTLIB} pam

MODULES =		devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

# sudo-rs always authenticates through PAM; OpenBSD has no PAM in the
# base system, so the OpenPAM port is required and a /etc/pam.d/sudo
# service must be configured before the program can be used.
LIB_DEPENDS =		security/openpam

# Upstream only supports Linux and FreeBSD.  The patches under patches/
# add the OpenBSD bits: the platform guard, the PAM bindings selection,
# closefrom(2) instead of close_range(2), sysctl(2)-based process
# information, POLLRDHUP and the AT_EMPTY_PATH permission check.
# The result is a first porting attempt and needs to be built and tested
# on OpenBSD; see pkg/DESCR.
MODCARGO_INSTALL =	No

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/sudo ${PREFIX}/bin/sudo
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/visudo ${PREFIX}/sbin/visudo
	ln -sf sudo ${PREFIX}/bin/sudoedit
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/sudo-rs
	${INSTALL_DATA} ${FILESDIR}/sudoers ${PREFIX}/share/examples/sudo-rs/sudoers
	${INSTALL_MAN_DIR} ${PREFIX}/man/man5 ${PREFIX}/man/man8
	${INSTALL_MAN} ${WRKSRC}/docs/man/sudo.8.man ${PREFIX}/man/man8/sudo.8
	${INSTALL_MAN} ${WRKSRC}/docs/man/visudo.8.man ${PREFIX}/man/man8/visudo.8
	${INSTALL_MAN} ${WRKSRC}/docs/man/sudoers.5.man ${PREFIX}/man/man5/sudoers.5
	ln -sf sudo.8 ${PREFIX}/man/man8/sudoedit.8

.include "crates.inc"

.include <bsd.port.mk>
