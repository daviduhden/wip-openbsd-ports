COMMENT =		human-readable ANSI escape sequence inspector

MODGO_MODNAME =		github.com/charmbracelet/sequin
MODGO_VERSION =		v0.3.1

DISTNAME =		sequin-${MODGO_VERSION}

CATEGORIES =		devel

HOMEPAGE =		https://github.com/charmbracelet/sequin

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
