COMMENT =	i2p-only BitTorrent client written in Go

MODGO_MODNAME =	github.com/majestrate/XD
MODGO_VERSION =	v0.4.6

DISTNAME =	xd-torrent-${MODGO_VERSION}

CATEGORIES =	net

HOMEPAGE =	https://xd-torrent.github.io/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/go

WRKDIST =		${WRKSRC}

post-install:
	ln -s XD ${PREFIX}/bin/XD-CLI

.include "modules.inc"
.include <bsd.port.mk>