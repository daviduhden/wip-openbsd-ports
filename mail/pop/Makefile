COMMENT =		terminal email client

MODGO_MODNAME =		github.com/charmbracelet/pop
MODGO_VERSION =		v0.5.0

DISTNAME =		pop-${MODGO_VERSION}

CATEGORIES =		mail

HOMEPAGE =		https://github.com/charmbracelet/pop

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
