COMMENT =	FIDO2 authenticator management CLI

V =		0.2.0
DISTNAME =	fido2-manage-${V}
GH_ACCOUNT =	token2
GH_PROJECT =	fido2-manage
GH_TAGNAME =	${V}
CATEGORIES =	security
HOMEPAGE =	https://github.com/token2/fido2-manage

# BSD 2-Clause
PERMIT_PACKAGE =	Yes

WANTLIB +=	${MODCARGO_WANTLIB} fido2

MODULES =	devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

MODCARGO_CARGOTOML =	${WRKSRC}/token2-piv-gui/src-tauri/Cargo.toml
MODCARGO_CARGOLOCK =	${WRKSRC}/token2-piv-gui/src-tauri/Cargo.lock
MODCARGO_INSTALL =	No
MODCARGO_BUILD_ARGS +=	--locked --no-default-features --features cli \
			--bin fido2-manage


do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/fido2-manage \
		${PREFIX}/bin/fido2-manage
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/fido2-manage
	${INSTALL_DATA} ${WRKSRC}/README.md \
		${PREFIX}/share/doc/fido2-manage/README.md
	${INSTALL_DATA} ${WRKSRC}/token2-piv-gui/FIDO2-MANAGE.md \
		${PREFIX}/share/doc/fido2-manage/FIDO2-MANAGE.md
	${INSTALL_DATA} ${WRKSRC}/token2-piv-tool/COPYING \
		${PREFIX}/share/doc/fido2-manage/COPYING
	${INSTALL_DATA} ${.CURDIR}/README.port \
		${PREFIX}/share/doc/fido2-manage/PORTING.md

.if exists(${.CURDIR}/crates.inc)
.include "crates.inc"
.endif

.include <bsd.port.mk>
