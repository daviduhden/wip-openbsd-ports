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

TEST_TARGET =		./...

# glow's release build takes main.Version from charmbracelet/meta's
# goreleaser-glow.yaml, which uses {{ .Version }} (the tag without its leading
# "v"), so the published binaries report "3.0.0".  Pass the numeric form.
MODGO_LDFLAGS +=	-X main.Version=${MODGO_VERSION:S/^v//}

.include "modules.inc"

.include <bsd.port.mk>
