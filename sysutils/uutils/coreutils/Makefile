COMMENT =	alternative implementation of GNU coreutils

GH_PROJECT =	coreutils
GH_TAGNAME =	0.12.0

WANTLIB += ${MODCARGO_WANTLIB} m

# Build each utility as an independent executable instead of the
# multicall coreutils binary.  Upstream's GNUmakefile supports this with
# MULTICALL=n (its default); it also derives the utility list and handles
# the test/[ alias.  Man pages, shell completions and locales are left to
# their own ports, so they are disabled here.
BUILD_DEPENDS +=	devel/gmake
MODCARGO_INSTALL =	No

GMAKE =			${LOCALBASE}/bin/gmake
GMAKE_FLAGS =		MULTICALL=n PROFILE=release \
			LOCALES=n MANPAGES=n COMPLETIONS=n \
			CARGO=${MODCARGO_CARGO_BIN}

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${GMAKE} build ${GMAKE_FLAGS}

do-install:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${GMAKE} install ${GMAKE_FLAGS} \
		DESTDIR=${WRKINST} PREFIX=${PREFIX} PROG_PREFIX=uu-

.include "crates.inc"

.include <bsd.port.mk>
