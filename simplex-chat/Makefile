COMMENT = Private and encrypted chat platform (terminal client)

DEBUG ?= 0

.if ${DEBUG} == 1
CABAL_FLAGS = -v2
.else
CABAL_FLAGS = -j
.endif

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplex-chat
GH_COMMIT = f144bf45607e8838c250bae424660658844457f4

DISTNAME = simplex-chat-6.5.4.1
WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_COMMIT}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

CATEGORIES = net
HOMEPAGE = https://simplex.chat/

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

BUILD_DEPENDS = devel/cabal-install \
			lang/ghc \
			net/simplexmq

CABAL_STATE_ROOT = ${WRKDIR}/.cabal-state
MAKE_ENV += XDG_CACHE_HOME=${CABAL_STATE_ROOT}/cache
MAKE_ENV += HOME=${CABAL_STATE_ROOT}/home
MAKE_ENV += CABAL_DIR=${CABAL_STATE_ROOT}/cabal
MAKE_ENV += CABAL_UNVEIL=0

LIB_DEPENDS = databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS = databases/sqlcipher \
			archivers/zstd

do-build:
	install -d ${CABAL_STATE_ROOT}/home ${CABAL_STATE_ROOT}/cache ${CABAL_STATE_ROOT}/cabal
	cd ${WRKSRC} && env ${MAKE_ENV} cabal update && \
		env ${MAKE_ENV} cabal build ${CABAL_FLAGS}

do-test:
	cd ${WRKSRC} && env ${MAKE_ENV} cabal update && \
		env ${MAKE_ENV} cabal test ${CABAL_FLAGS}

do-install:
	chat=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/simplex-chat/build/simplex-chat/simplex-chat' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$chat" ${PREFIX}/bin/simplex-chat

.include <bsd.port.mk>
