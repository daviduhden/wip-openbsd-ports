COMMENT = SimpleX messaging protocol server and client library

DEBUG ?= 0

.if ${DEBUG} == 1
CABAL_FLAGS = -v2
.else
CABAL_FLAGS = -j
.endif

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplexmq
GH_COMMIT = 9f9b6c8e88524fb5fd063f47617a679ea53ac7c0

DISTNAME = simplexmq-6.5.3.0
WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_COMMIT}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

CATEGORIES = net
HOMEPAGE = https://simplex.chat/

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

WANTLIB = ${COMPILER_LIBCXX} c crypto ffi gmp iconv m pthread util z

BUILD_DEPENDS = devel/cabal-install \
			lang/ghc

MAKE_ENV += XDG_CACHE_HOME=${WRKDIR}/.cache
MAKE_ENV += HOME=${WRKDIR}
MAKE_ENV += CABAL_DIR=${WRKDIR}/.cabal
MAKE_ENV += DEBUG=${DEBUG}
MAKE_ENV += CC=/usr/bin/clang
MAKE_ENV += CXX=/usr/bin/clang++
MAKE_ENV += LIBRARY_PATH=/usr/lib:/usr/local/lib

LIB_DEPENDS = converters/libiconv \
			devel/gmp \
			devel/libffi

do-build:
	ksh ${FILESDIR}/setup-deps.ksh ${WRKDIR} ${FILESDIR}
	cd ${WRKSRC} && env ${MAKE_ENV} cabal update && \
		env ${MAKE_ENV} cabal build ${CABAL_FLAGS}

do-test:
	ksh ${FILESDIR}/setup-deps.ksh ${WRKDIR} ${FILESDIR}
	cd ${WRKSRC} && env ${MAKE_ENV} cabal update && \
		env ${MAKE_ENV} cabal test ${CABAL_FLAGS}

do-install:
	smp=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/smp-server/build/smp-server/smp-server' | head -n 1); \
	xftp_server=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/xftp-server/build/xftp-server/xftp-server' | head -n 1); \
	env ${MAKE_ENV} cabal install --lib simplexmq; \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$smp" ${PREFIX}/bin/smp-server; \
	install -m 755 "$$xftp_server" ${PREFIX}/bin/xftp-server

.include <bsd.port.mk>
