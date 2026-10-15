COMMENT =		SSH server with terminal visual effects

MODGO_MODNAME =		github.com/charmbracelet/confettysh
MODGO_VERSION =		v1.1.2

DISTNAME =		confettysh-${MODGO_VERSION}
WRKDIST =		${WRKDIR}/${MODGO_MODNAME}@${MODGO_VERSION}

CATEGORIES =		misc

HOMEPAGE =		https://github.com/charmbracelet/confettysh

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

TEST_TARGET =		./...

.include "modules.inc"

.include <bsd.port.mk>
