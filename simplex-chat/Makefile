COMMENT =		Private and encrypted chat platform (terminal client)

V =			6.5.3.0
DISTNAME =		simplex-chat-${V}

CATEGORIES =		net

HOMEPAGE =		https://github.com/simplex-chat/simplex-chat

MAINTAINER =		Porting Team <ports@example.org>

# AGPL-3
PERMIT_PACKAGE =	Yes

# Uses GitHub-tagged releases
GH_ACCOUNT =		simplex-chat
GH_PROJECT =		simplex-chat
GH_TAGNAME =		v${V}

MODULES =		lang/ghc

BUILD_DEPENDS =		devel/cabal-install \
			devel/git

LIB_DEPENDS =		databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS =		databases/sqlcipher \
			archivers/zstd \
			simplexmq->=6.5.2.0:net/simplexmq

do-build:
	cd ${WRKSRC} && cabal update && cabal build -j

do-install:
	cd ${WRKSRC} && cabal install \
		--installdir=${PREFIX}/bin

NO_TEST =		Yes

.include <bsd.port.mk>
