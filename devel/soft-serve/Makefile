COMMENT =		self-hosted Git server for the command line

MODGO_MODNAME =		github.com/charmbracelet/soft-serve
MODGO_VERSION =		v0.12.4

DISTNAME =		soft-serve-${MODGO_VERSION}

CATEGORIES =		devel

HOMEPAGE =		https://github.com/charmbracelet/soft-serve

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

TEST_TARGET =		./...

# Go does not support the race detector on OpenBSD.
TEST_ENV +=		SOFT_SERVE_DISABLE_RACE_CHECKS=1
TEST_DEPENDS =		devel/git-lfs

# Repository access is delegated to the system git executable.
RUN_DEPENDS =		devel/git

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/soft-serve
	${INSTALL_DATA} ${WRKSRC}/README.md ${PREFIX}/share/doc/soft-serve/

.include "modules.inc"

.include <bsd.port.mk>
