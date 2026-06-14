COMMENT = SimpleX messaging protocol server and client library
V = 6.5.3.0
SPLITMIX_V = 0.1.3.1
DISTNAME = simplexmq-${V}
WRKDIST = ${WRKDIR}/simplexmq-stable
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

CATEGORIES = net
HOMEPAGE = https://simplex.chat/
SITES = https://github.com/simplex-chat/
SITES.hs = https://hackage.haskell.org/package/
DISTFILES = simplexmq-${V}${EXTRACT_SUFX}{simplexmq/archive/refs/heads/stable.tar.gz}
DISTFILES.hs += splitmix-${SPLITMIX_V}.tar.gz
EXTRACT_ONLY = simplexmq-${V}${EXTRACT_SUFX}
EXTRACT_ONLY += splitmix-${SPLITMIX_V}.tar.gz

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

WANTLIB = ${COMPILER_LIBCXX} c crypto ffi gmp iconv m pthread util z

BUILD_DEPENDS = devel/cabal-install \
			lang/ghc

MAKE_ENV += XDG_CACHE_HOME=${WRKDIR}/.cache
MAKE_ENV += HOME=${WRKDIR}
MAKE_ENV += CABAL_DIR=${WRKDIR}/.cabal

LIB_DEPENDS = converters/libiconv \
			devel/gmp \
			devel/libffi

post-extract:
	tar -C ${WRKSRC} -xzf ${FULLDISTDIR}/splitmix-${SPLITMIX_V}.tar.gz

do-build:
	cd ${WRKSRC} && env HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
		CABAL_DIR=${WRKDIR}/.cabal cabal update && \
		sh ${FILESDIR}/patch-hashable-cache.ksh \
		${WRKDIR}/.cabal/packages/hackage.haskell.org/hashable/1.4.3.0/hashable-1.4.3.0.tar.gz \
		${FILESDIR}/patch-hashable-1_4_3_0_hashable_cabal && \
		env HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
		CABAL_DIR=${WRKDIR}/.cabal cabal build -j

do-test:
	cd ${WRKSRC} && env HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
		CABAL_DIR=${WRKDIR}/.cabal cabal update && \
		sh ${FILESDIR}/patch-hashable-cache.ksh \
		${WRKDIR}/.cabal/packages/hackage.haskell.org/hashable/1.4.3.0/hashable-1.4.3.0.tar.gz \
		${FILESDIR}/patch-hashable-1_4_3_0_hashable_cabal && \
		env HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
		CABAL_DIR=${WRKDIR}/.cabal cabal test -j

do-install:
	smp=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/smp-server/build/smp-server/smp-server' | head -n 1); \
	xftp_server=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/xftp-server/build/xftp-server/xftp-server' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$smp" ${PREFIX}/bin/smp-server; \
	install -m 755 "$$xftp_server" ${PREFIX}/bin/xftp-server

.include <bsd.port.mk>
