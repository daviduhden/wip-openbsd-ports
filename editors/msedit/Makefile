ONLY_FOR_ARCHS =		amd64 aarch64

COMMENT =		Microsoft terminal text editor

GH_ACCOUNT =		microsoft
GH_PROJECT =		edit
GH_TAGNAME =		v2.0.0
PKGNAME =		msedit-${GH_TAGNAME:S/v//}
CATEGORIES =		editors

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		${MODCARGO_WANTLIB} m

MODULES =		devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

MODCARGO_BUILD_ARGS =	--locked -p edit --bin edit
MODCARGO_INSTALL =	No

# ICU is loaded with dlopen(), not linked. OpenBSD disables symbol renaming.
RUN_DEPENDS =		textproc/icu4c
MODCARGO_ENV +=		EDIT_CFG_ICU_RENAMING_AUTO_DETECT=false \
			EDIT_CFG_ICUUC_SONAME=${LOCALBASE}/lib/libicuuc.so \
			EDIT_CFG_ICUI18N_SONAME=${LOCALBASE}/lib/libicui18n.so

# Only the upstream test/benchmark dependencies use zstd.
TEST_DEPENDS =		archivers/zstd

# stdext's should_panic doctest exercises the debug arena implementation.
do-test:
	${MODCARGO_CARGO_RUN} test --locked -p edit -p lsh -p stdext

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/edit \
		${PREFIX}/bin/msedit
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/msedit
	${INSTALL_DATA} ${WRKSRC}/LICENSE \
		${PREFIX}/share/doc/msedit/

.include "crates.inc"
.include <bsd.port.mk>
