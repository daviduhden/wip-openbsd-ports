COMMENT =		generate images of code and terminal output

MODGO_MODNAME =		github.com/charmbracelet/freeze
MODGO_VERSION =		v0.2.2

DISTNAME =		freeze-${MODGO_VERSION}
# archivers/freeze owns bin/freeze as well, so give this package a
# distinct name and declare the conflict below.
PKGNAME =		charm-freeze-${MODGO_VERSION:S/v//}

CATEGORIES =		graphics

HOMEPAGE =		https://github.com/charmbracelet/freeze

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		c pthread

MODULES =		lang/go

# freeze rasterises its generated SVG with rsvg-convert when it is
# present, and only falls back to the bundled resvg WebAssembly renderer
# otherwise. The fallback needs executable memory mappings, so pull in
# librsvg to get the preferred SVG rasteriser.
RUN_DEPENDS =		x11/gnome/librsvg

# Upstream release binaries inject the tag version into main.Version.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION}

.include "modules.inc"

.include <bsd.port.mk>
