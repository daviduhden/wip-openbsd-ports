ONLY_FOR_ARCHS =		amd64 aarch64

COMMENT-main =		RPC client for the Mullvad VPN daemon
COMMENT-daemon =		privileged Mullvad VPN backend (incomplete)

GH_ACCOUNT =		mullvad
GH_PROJECT =		mullvadvpn-app
GH_TAGNAME =		2026.4
PKGNAME-main =		mullvad-cli-${GH_TAGNAME}
PKGNAME-daemon =		mullvad-daemon-${GH_TAGNAME}
CATEGORIES =		net
HOMEPAGE =		https://mullvad.net/

# GPL-3.0-or-later; crate licenses are recorded in crates.inc.
PERMIT_PACKAGE =	Yes

MULTI_PACKAGES =		-main
PSEUDO_FLAVORS =		no_daemon
FLAVOR ?=		no_daemon

# Current -current module is devel/cargo, not lang/cargo.
MODULES =		devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes
MODCARGO_INSTALL =	No
MODCARGO_NO_DEFAULT_FEATURES = Yes
MODCARGO_BUILD_ARGS =	--locked -p mullvad-cli --bin mullvad
MODCARGO_ENV +=		MULLVAD_BUILD_FROM_ARCHIVE=1
BUILD_DEPENDS =		devel/protobuf
WANTLIB-main +=		${MODCARGO_WANTLIB} m
WANTLIB-daemon +=	${MODCARGO_WANTLIB} m

UDP_COMMIT =		5c6d8f44a5aa12ed9bb4ae51dd17e5e22e5ec303
SITES.udp =		https://github.com/mullvad/udp-over-tcp/archive/
DISTFILES.udp =		udp-over-tcp-${UDP_COMMIT:C/(........).*/\1/}{${UDP_COMMIT}}.tar.gz

# One source/lock/vendor set for both deliverables. Do not enable an unsafe
# daemon just to produce a package. See OPENBSD.md for the remaining gates.
.if empty(FLAVOR:Mno_daemon)
MULTI_PACKAGES +=	-daemon
BROKEN =		OpenBSD TUN, routing, PF and DNS integration is incomplete
MODCARGO_BUILD_ARGS +=	-p mullvad-daemon --bin mullvad-daemon
.endif

post-extract:
	${INSTALL_DATA_DIR} ${WRKSRC}/vendor
	mv ${WRKDIR}/udp-over-tcp-${UDP_COMMIT} ${WRKSRC}/vendor/
	cp -R ${FILESDIR}/talpid-openbsd ${WRKSRC}/
	${INSTALL_DATA} ${FILESDIR}/Cargo.lock ${WRKSRC}/Cargo.lock

do-test:
	${MODCARGO_CARGO_RUN} test --locked -p mullvad-cli \
		-p mullvad-management-interface -p mullvad-types \
		-p mullvad-version -p talpid-types -p talpid-openbsd

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/mullvad ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/mullvad
	${INSTALL_DATA} ${WRKSRC}/LICENSE.md ${PREFIX}/share/doc/mullvad/
.if empty(FLAVOR:Mno_daemon)
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/mullvad-daemon ${PREFIX}/sbin/
	${INSTALL_DATA_DIR} ${PREFIX}/share/mullvad
	${INSTALL_DATA} ${WRKSRC}/dist-assets/ca.crt \
		${WRKSRC}/dist-assets/relays/relays.json ${PREFIX}/share/mullvad/
.endif

.include "crates.inc"
.include <bsd.port.mk>
