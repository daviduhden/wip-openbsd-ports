COMMENT =		Private and encrypted chat platform (terminal client)
V =			6.5.4.0
SIMPLEXMQ_V =		6.5.3.0
DISTNAME =		simplex-chat-${V}
WRKDIST =		${WRKDIR}/simplex-chat-stable
WRKSRC =		${WRKDIST}
ONLY_FOR_ARCHS =	amd64 arm64

CATEGORIES =		net

HOMEPAGE =		https://simplex.chat/
SITES =			https://github.com/simplex-chat/ \
			https://github.com/yesodweb/
SITES.hs =		https://hackage.haskell.org/package/
DISTFILES =		simplex-chat-${V}${EXTRACT_SUFX}{simplex-chat/archive/refs/heads/stable.tar.gz}
EXTRACT_ONLY =		simplex-chat-${V}${EXTRACT_SUFX}

MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE =	Yes

BUILD_DEPENDS =		devel/cabal-install \
			lang/ghc

BUILD_DEPENDS +=	simplexmq->=${SIMPLEXMQ_V}:net/simplexmq

MAKE_ENV +=		XDG_CACHE_HOME=${WRKDIR}/.cache

LIB_DEPENDS =		databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS =		databases/sqlcipher \
			archivers/zstd \
			simplexmq->=${SIMPLEXMQ_V}:net/simplexmq

TEST_ENV =		HOME=${WRKSRC} \
			XDG_CACHE_HOME=${WRKSRC}/.cache \
			CABAL_DIR=${WRKSRC}/.cabal

post-extract:
	cp ${FILESDIR}/cabal.project ${WRKSRC}/cabal.project
	cp ${FILESDIR}/cabal.project.local ${WRKSRC}/cabal.project.local
	cp ${FILESDIR}/simplex-chat.cabal ${WRKSRC}/simplex-chat.cabal
	tar -C ${WRKSRC} -xzf ${FULLDISTDIR}/splitmix-${SPLITMIX_V}.tar.gz
	cp ${FULLDISTDIR}/aeson-${AESON_V}-rev${AESON_REV}.cabal ${WRKDIR}/aeson-${AESON_V}/aeson.cabal
	cp ${FULLDISTDIR}/unliftio-core-${UNLIFTIO_CORE_V}-rev${UNLIFTIO_CORE_REV}.cabal ${WRKDIR}/unliftio-core-${UNLIFTIO_CORE_V}/unliftio-core.cabal
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/prettyprinter-version-compatibility-macros.patch
	cp ${FULLDISTDIR}/vector-stream-${VECTOR_STREAM_V}-rev${VECTOR_STREAM_REV}.cabal ${WRKDIR}/vector-stream-${VECTOR_STREAM_V}/vector-stream.cabal
	cp ${FULLDISTDIR}/generically-${GENERICALLY_V}-rev${GENERICALLY_REV}.cabal ${WRKDIR}/generically-${GENERICALLY_V}/generically.cabal
	cp ${FULLDISTDIR}/ghc-bignum-orphans-${GHC_BIGNUM_ORPHANS_V}-rev${GHC_BIGNUM_ORPHANS_REV}.cabal ${WRKDIR}/ghc-bignum-orphans-${GHC_BIGNUM_ORPHANS_V}/ghc-bignum-orphans.cabal
	cp ${FULLDISTDIR}/network-uri-${NETWORK_URI_V}-rev${NETWORK_URI_REV}.cabal ${WRKDIR}/network-uri-${NETWORK_URI_V}/network-uri.cabal

do-build:
	cd ${WRKSRC} && env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal update && \
		env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal build -j exe:simplex-chat

do-test:
	cd ${WRKSRC} && env ${TEST_ENV} cabal update && \
	env ${TEST_ENV} cabal test simplex-chat-test --test-show-details=direct

do-install:
	chat=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/simplex-chat/build/simplex-chat/simplex-chat' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$chat" ${PREFIX}/bin/simplex-chat

.include "simplex-chat.inc"
.include "simplex-chat.distfiles.inc"

.include <bsd.port.mk>
