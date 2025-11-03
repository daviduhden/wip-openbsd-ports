COMMENT =	i2p-only BitTorrent client written in Go

MODGO_MODNAME =	github.com/majestrate/XD
MODGO_VERSION =	v0.4.7

DISTNAME =	xd-torrent-${MODGO_VERSION}

CATEGORIES =	net

HOMEPAGE =	https://xd-torrent.github.io/

# MIT
PERMIT_PACKAGE =	Yes
ONLY_FOR_ARCHS =	${GO_ARCHS}

WANTLIB += c pthread

MODULES =		lang/go

LIB_DEPENDS =		archivers/unzip
RUN_DEPENDS =		net/i2pd

WRKDIST =		${WRKSRC}

post-install:
	ln -s XD ${PREFIX}/bin/XD-CLI

.include "modules.inc"
.include <bsd.port.mk>