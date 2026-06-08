COMMENT = Private and encrypted chat platform (terminal client)
# Keep the client release version separate from the server dependency pin so
# the terminal client can track upstream independently.
V = 6.5.4.0
SIMPLEXMQ_V = 6.5.3.0
DISTNAME = simplex-chat-${V}
WRKDIST = ${WRKDIR}/simplex-chat-${V:R}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

CATEGORIES = net

HOMEPAGE = https://simplex.chat/
# Upstream client sources come from GitHub; dependency pins are centralized
# in simplex-chat.distfiles.inc.
SITES = https://github.com/simplex-chat/ \
			https://github.com/yesodweb/
SITES.hs =		https://hackage.haskell.org/package/
DISTFILES = simplex-chat-${V}${EXTRACT_SUFX}{simplex-chat/archive/refs/heads/stable.tar.gz}
EXTRACT_ONLY = simplex-chat-${V}${EXTRACT_SUFX}

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

BUILD_DEPENDS = devel/cabal-install \
			lang/ghc
BUILD_DEPENDS += simplexmq->=${SIMPLEXMQ_V}:net/simplexmq

MAKE_ENV += XDG_CACHE_HOME=${WRKDIR}/.cache

LIB_DEPENDS = databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS = databases/sqlcipher \
			archivers/zstd \
			simplexmq->=${SIMPLEXMQ_V}:net/simplexmq

NO_TEST = Yes

post-extract:
	# Copy the port-local Cabal files first, then unpack the dependency trees
	# needed by the upstream cabal.project.local layout.
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
	# Build only the terminal client executable installed by this port.
	cd ${WRKSRC} && env HOME=${WRKSRC} XDG_CACHE_HOME=${WRKSRC}/.cache \
		CABAL_DIR=${WRKSRC}/.cabal cabal build --offline -j exe:simplex-chat

do-install:
	# Install only the client binary produced by the build.
	chat=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/simplex-chat/build/simplex-chat/simplex-chat' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$chat" ${PREFIX}/bin/simplex-chat

	.include "simplex-chat.inc"
.include "simplex-chat.distfiles.inc"

.include <bsd.port.mk>