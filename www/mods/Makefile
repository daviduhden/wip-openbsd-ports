COMMENT =		AI on the command line

MODGO_MODNAME =		github.com/charmbracelet/mods
MODGO_VERSION =		v1.8.1

DISTNAME =		mods-${MODGO_VERSION}

CATEGORIES =		www

HOMEPAGE =		https://github.com/charmbracelet/mods

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
