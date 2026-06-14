COMMENT = Private and encrypted chat platform (terminal client)
V = 6.5.4.1
V_BASE = ${V:C/\.[0-9]+$//}
SIMPLEXMQ_V = 6.5.3.0
DISTNAME = simplex-chat-${V}
WRKDIST = ${WRKDIR}/simplex-chat-${V_BASE}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

CATEGORIES = net
HOMEPAGE = https://simplex.chat/
SITES = https://github.com/simplex-chat/
SITES.hs = https://hackage.haskell.org/package/
DISTFILES = simplex-chat-${V}${EXTRACT_SUFX}{simplex-chat/archive/refs/heads/stable.tar.gz}
DISTFILES += simplexmq-${SIMPLEXMQ_V}${EXTRACT_SUFX}{simplexmq/archive/refs/heads/stable.tar.gz}
EXTRACT_ONLY = simplex-chat-${V}${EXTRACT_SUFX}
EXTRACT_ONLY += simplexmq-${SIMPLEXMQ_V}${EXTRACT_SUFX}

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

BUILD_DEPENDS = devel/cabal-install \
			lang/ghc

CABAL_STATE_ROOT = ${WRKDIR}/.cabal-state
MAKE_ENV += XDG_CACHE_HOME=${CABAL_STATE_ROOT}/cache
MAKE_ENV += HOME=${CABAL_STATE_ROOT}/home
MAKE_ENV += CABAL_DIR=${CABAL_STATE_ROOT}/cabal

LIB_DEPENDS = databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS = databases/sqlcipher \
			archivers/zstd

post-extract:
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/patch-simplexmq-stable_src_Simplex_Messaging_Transport_KeepAlive_hs

do-build:
	install -d ${CABAL_STATE_ROOT}/home ${CABAL_STATE_ROOT}/cache ${CABAL_STATE_ROOT}/cabal
	cd ${WRKSRC} && env ${MAKE_ENV} cabal update && \
		sh ${FILESDIR}/patch-hashable-cache.ksh \
		${CABAL_STATE_ROOT}/cabal/packages/hackage.haskell.org/hashable/1.4.3.0/hashable-1.4.3.0.tar.gz \
		${FILESDIR}/patch-hashable-1_4_3_0_hashable_cabal && \
		env ${MAKE_ENV} cabal build --allow-newer -j

do-test:
	cd ${WRKSRC} && env ${MAKE_ENV} cabal update && \
		sh ${FILESDIR}/patch-hashable-cache.ksh \
		${CABAL_STATE_ROOT}/cabal/packages/hackage.haskell.org/hashable/1.4.3.0/hashable-1.4.3.0.tar.gz \
		${FILESDIR}/patch-hashable-1_4_3_0_hashable_cabal && \
		env ${MAKE_ENV} cabal test --allow-newer -j

do-install:
	chat=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/simplex-chat/build/simplex-chat/simplex-chat' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$chat" ${PREFIX}/bin/simplex-chat

.include <bsd.port.mk>
