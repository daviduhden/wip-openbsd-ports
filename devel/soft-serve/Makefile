COMMENT =		self-hosted Git server for the command line

MODGO_MODNAME =		github.com/charmbracelet/soft-serve
MODGO_VERSION =		v0.12.3

DISTNAME =		soft-serve-${MODGO_VERSION}

CATEGORIES =		devel

HOMEPAGE =		https://github.com/charmbracelet/soft-serve

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Repository access is delegated to the system git executable.
RUN_DEPENDS =		devel/git

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/soft-serve
	${INSTALL_DATA} ${WRKSRC}/README.md ${PREFIX}/share/doc/soft-serve/

.include "modules.inc"

.include <bsd.port.mk>
