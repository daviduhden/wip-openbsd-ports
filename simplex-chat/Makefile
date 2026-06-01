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

TEST_ENV =		HOME=${WRKSRC} \
			XDG_CACHE_HOME=${WRKSRC}/.cache \
			CABAL_DIR=${WRKSRC}/.cabal

ENTROPY_SRC =		${WRKSRC}/.entropy/entropy-0.4.1.11

pre-build pre-test:
	env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal update && \
	if [ ! -f ${ENTROPY_SRC}/Setup.hs ]; then \
		mkdir -p ${WRKSRC}/.entropy && \
		ftp -o ${WRKSRC}/.entropy/entropy-0.4.1.11.tar.gz \
			https://hackage.haskell.org/package/entropy-0.4.1.11/entropy-0.4.1.11.tar.gz && \
		cd ${WRKSRC}/.entropy && tar -xzf entropy-0.4.1.11.tar.gz; \
		cd ${ENTROPY_SRC} && patch -N --batch -p0 -F0 < ${.CURDIR}/../simplexmq/files/entropy-setup-openbsd.patch; \
	fi

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

pre-test:
	cp ${WRKSRC}/scripts/cabal.project.local.linux ${WRKSRC}/cabal.project.local
	printf '%s\n' "packages: ./.entropy/entropy-0.4.1.11" >> ${WRKSRC}/cabal.project.local

do-build:
	cd ${WRKSRC} && env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal update && \
		env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal build -j exe:simplex-chat

do-test:
	cd ${WRKSRC} && env ${TEST_ENV} cabal update && \
	env ${TEST_ENV} cabal build -j simplex-chat-test && \
	env ${TEST_ENV} cabal test simplex-chat-test

do-install:
	chat=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/simplex-chat/build/simplex-chat/simplex-chat' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$chat" ${PREFIX}/bin/simplex-chat

.include <bsd.port.mk>
