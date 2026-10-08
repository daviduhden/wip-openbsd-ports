COMMENT =		render markdown on the command line

MODGO_MODNAME =		charm.land/glow/v3
MODGO_VERSION =		v3.0.0

DISTNAME =		glow-${MODGO_VERSION}

CATEGORIES =		textproc

HOMEPAGE =		https://github.com/charmbracelet/glow

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
