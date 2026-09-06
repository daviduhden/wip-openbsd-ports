COMMENT =		linter for Makefiles

MODGO_MODNAME =		github.com/checkmake/checkmake
MODGO_VERSION =		v0.3.2
DISTNAME =		checkmake-${MODGO_VERSION}
CATEGORIES =		devel
HOMEPAGE =		https://github.com/checkmake/checkmake

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Use the generated release manual; no Pandoc or development linter needed.
SITES.man =		https://github.com/checkmake/checkmake/releases/download/${MODGO_VERSION}/
DISTFILES.man =		checkmake-${MODGO_VERSION:S/v//}.1{checkmake.1}

MODGO_LDFLAGS +=		-X main.version=${MODGO_VERSION} \
			-X main.builder=OpenBSD \
			-X main.buildTime=release
TEST_TARGET =		./...

post-install:
	${INSTALL_MAN} ${FULLDISTDIR}/checkmake-${MODGO_VERSION:S/v//}.1 \
		${PREFIX}/man/man1/checkmake.1
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/checkmake
	${INSTALL_DATA} ${WRKSRC}/LICENSE ${PREFIX}/share/doc/checkmake/

.include "modules.inc"
.include <bsd.port.mk>
