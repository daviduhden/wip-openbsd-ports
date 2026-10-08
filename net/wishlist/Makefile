COMMENT =		the SSH directory

MODGO_MODNAME =		github.com/charmbracelet/wishlist
MODGO_VERSION =		v0.15.2

DISTNAME =		wishlist-${MODGO_VERSION}

CATEGORIES =		net

HOMEPAGE =		https://github.com/charmbracelet/wishlist

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
