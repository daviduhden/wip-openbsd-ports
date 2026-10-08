COMMENT =		CLI home video recorder

MODGO_MODNAME =		github.com/charmbracelet/vhs
MODGO_VERSION =		v0.12.1

DISTNAME =		vhs-${MODGO_VERSION}

CATEGORIES =		multimedia

HOMEPAGE =		https://github.com/charmbracelet/vhs

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# Recording a tape needs the ttyd terminal server, ffmpeg for encoding,
# bash as the default recording shell, and a Chromium-based browser. The
# go-rod launcher finds /usr/local/bin/chrome from www/chromium, so no
# browser is downloaded at run time.
RUN_DEPENDS =		graphics/ffmpeg \
			shells/bash \
			www/chromium \
			www/ttyd

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
