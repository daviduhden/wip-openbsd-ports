COMMENT =		Private and encrypted chat platform (terminal client)

V =			6.5.3.0
SIMPLEXMQ_V =		6.5.2.0
DIRECT_SQLCIPHER_V =	2.3.28
SQLCIPHER_SIMPLE_V =	0.4.18.1
DISTNAME =		simplex-chat-${V}
WRKDIST =		${WRKDIR}/simplex-chat-${V:R}
WRKSRC =		${WRKDIST}
ONLY_FOR_ARCHS =	amd64 arm64

CATEGORIES =		net

HOMEPAGE =		https://github.com/simplex-chat/simplex-chat

MAINTAINER =		Porting Team <ports@example.org>

# AGPL-3
PERMIT_PACKAGE =	Yes

SITES =			https://codeload.github.com/simplex-chat/
DISTFILES =		simplex-chat-${V}${EXTRACT_SUFX}{simplex-chat/tar.gz/refs/tags/v${V:R}}
DISTFILES +=		simplexmq-${SIMPLEXMQ_V}${EXTRACT_SUFX}{simplexmq/tar.gz/refs/tags/v${SIMPLEXMQ_V:R}}
DISTFILES +=		direct-sqlcipher-${DIRECT_SQLCIPHER_V}${EXTRACT_SUFX}{direct-sqlcipher/tar.gz/f814ee68b16a9447fbb467ccc8f29bdd3546bfd9}
DISTFILES +=		sqlcipher-simple-${SQLCIPHER_SIMPLE_V}${EXTRACT_SUFX}{sqlcipher-simple/tar.gz/a46bd361a19376c5211f1058908fc0ae6bf42446}

BUILD_DEPENDS =		devel/cabal-install \
			devel/git \
			lang/ghc

LIB_DEPENDS =		databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS =		databases/sqlcipher \
			archivers/zstd \
			simplexmq->=6.5.2.0:net/simplexmq

post-patch:
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq.cabal.patch
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq-keepalive.patch
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq-socks-client.patch
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq-socks-client-import.patch
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq-http2-client.patch
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${.CURDIR}/../simplexmq/patches/patch-parsers-objectwithsinglefield
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq-remotecontrol-types.patch
	cd ${WRKDIR}/simplexmq && patch -N --batch -p0 -F0 < ${FILESDIR}/simplexmq-http2-server.patch
post-extract:
	mv ${WRKDIR}/simplexmq-* ${WRKDIR}/simplexmq
	mv ${WRKDIR}/direct-sqlcipher-* ${WRKDIR}/direct-sqlcipher
	mv ${WRKDIR}/sqlcipher-simple-* ${WRKDIR}/sqlcipher-simple

do-build:
	cd ${WRKSRC} && env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal update && \
		env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal build -j exe:simplex-chat

do-install:
	chat=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/simplex-chat/build/simplex-chat/simplex-chat' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$chat" ${PREFIX}/bin/simplex-chat

.include <bsd.port.mk>
