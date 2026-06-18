COMMENT = SimpleX messaging protocol server and client library

DEBUG ?= 0

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplexmq
GH_COMMIT = 376d6a261a1074717aed65ad97bb6f2a9532011b

V = 6.5.4.0
DISTNAME = ${GH_PROJECT}-${V}
DISTFILES = ${GH_DISTFILE}
SITES = ${SITES_GITHUB}
WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_COMMIT}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

DIST_TUPLE += github simplex-chat aeson \
		aab7b5a14d6c5ea64c64dcaee418de1bb00dcc2b ../aeson
DIST_TUPLE += github simplex-chat hs-socks \
		a30cc7a79a08d8108316094f8f2f82a0c5e1ac51 ../hs-socks
DIST_TUPLE += github simplex-chat direct-sqlcipher \
		f814ee68b16a9447fbb467ccc8f29bdd3546bfd9 ../direct-sqlcipher
DIST_TUPLE += github simplex-chat sqlcipher-simple \
		a46bd361a19376c5211f1058908fc0ae6bf42446 ../sqlcipher-simple
DIST_TUPLE += github yesodweb wai \
		ec5e017d896a78e787a5acea62b37a4e677dec2e ../yesod-wai
DIST_TUPLE += github simplex-chat wai \
		2f6e5aa5f05ba9140ac99e195ee647b4f7d926b0 ../simplex-wai

CATEGORIES = net
HOMEPAGE = https://simplex.chat/

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

WANTLIB = ${COMPILER_LIBCXX} c crypto ffi gmp iconv m pthread util z

MODULES = devel/cabal
MODCABAL_STEM = simplexmq
MODCABAL_VERSION = ${V}
MODCABAL_EXECUTABLES = smp-server xftp-server

.if ${DEBUG} == 1
MODCABAL_BUILD_ARGS = -v2
.endif

CRYPTOSTORE_V = 0.5.0.0
NETWORK_V = 3.2.8.0
UNIX_TIME_V = 0.5.0
CABAL_INC_HOME ?= ${WRKDIR}/.cabal-inc-home
CABAL_INC_SKIP = aeson,socks,direct-sqlcipher,sqlcipher-simple,warp-tls,warp
CABAL_INC_EXTRA = wai-app-static:3.2.1:0,wai-extra:3.1.18:0,yaml:0.11.11.2:0

LIB_DEPENDS = converters/libiconv \
			devel/gmp \
			devel/libffi

post-patch:
	perl -0pi -e 's/\nsource-repository-package\n(?:    .*\n)+//g' \
		${WRKSRC}/cabal.project
	printf '%s\n' \
		'packages: ${WRKDIR}/aeson/aeson.cabal' \
		'packages: ${WRKDIR}/hs-socks/socks.cabal' \
		'packages: ${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal' \
		'packages: ${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal' \
		'packages: ${WRKDIR}/yesod-wai/warp-tls/warp-tls.cabal' \
		'packages: ${WRKDIR}/simplex-wai/warp/warp.cabal' \
		>> ${WRKSRC}/cabal.project.local
	patch -d ${WRKDIR}/aeson -p0 < ${FILESDIR}/patch-deps-aeson
	patch -d ${WRKDIR}/simplex-wai/warp -p0 < ${FILESDIR}/patch-deps-warp
	if [ -d ${WRKDIR}/cryptostore-${CRYPTOSTORE_V} ]; then \
		perl -pi -e 's/^(\s*,\s*)memory\b/$${1}ram/' \
			${WRKDIR}/cryptostore-${CRYPTOSTORE_V}/cryptostore.cabal; \
		patch -d ${WRKDIR}/cryptostore-${CRYPTOSTORE_V} -p0 \
			< ${FILESDIR}/patch-deps-cryptostore; \
	fi
	if [ -f ${WRKDIR}/network-${NETWORK_V}/network.cabal ]; then \
		perl -pi -e 's/^(build-type:\s*)Configure\b/\1Simple/i' \
			${WRKDIR}/network-${NETWORK_V}/network.cabal; \
		${INSTALL_DATA_DIR} ${WRKDIR}/network-${NETWORK_V}/include; \
		${INSTALL_DATA} ${FILESDIR}/HsNetworkConfig.h \
			${WRKDIR}/network-${NETWORK_V}/include/HsNetworkConfig.h; \
	fi
	if [ -f ${WRKDIR}/unix-time-${UNIX_TIME_V}/unix-time.cabal ]; then \
		perl -pi -e 's/^(build-type:\s*)Configure\b/\1Simple/i' \
			${WRKDIR}/unix-time-${UNIX_TIME_V}/unix-time.cabal; \
		${INSTALL_DATA} ${FILESDIR}/UnixTimeConfig.h \
			${WRKDIR}/unix-time-${UNIX_TIME_V}/cbits/config.h; \
	fi

cabal-inc: patch
	${INSTALL_DATA_DIR} ${CABAL_INC_HOME}
	${INSTALL_DATA_DIR} ${CABAL_INC_HOME}/.cabal
	env HOME=${CABAL_INC_HOME} CABAL_DIR=${CABAL_INC_HOME}/.cabal \
		LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal update
	if [ ! -f ${CABAL_INC_HOME}/.cabal/config ] && \
		[ -f ${CABAL_INC_HOME}/.config/cabal/config ]; then \
		cp ${CABAL_INC_HOME}/.config/cabal/config \
			${CABAL_INC_HOME}/.cabal/config; \
	fi
	cd ${WRKBUILD} && env HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal v2-build --dry-run \
		-w ${LOCALBASE}/bin/ghc \
		--disable-benchmarks --disable-tests \
		exe:smp-server exe:xftp-server
	cd ${WRKBUILD} && env HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal-bundler --openbsd \
		--plan dist-newstyle/cache/plan.json \
		--executable smp-server \
		${MODCABAL_STEM}-${MODCABAL_VERSION} \
		> ${WRKDIR}/simplexmq.smp.inc
	cd ${WRKBUILD} && env HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal-bundler --openbsd \
		--plan dist-newstyle/cache/plan.json \
		--executable xftp-server \
		${MODCABAL_STEM}-${MODCABAL_VERSION} \
		> ${WRKDIR}/simplexmq.xftp.inc
	env SKIP=${CABAL_INC_SKIP} EXTRA=${CABAL_INC_EXTRA} perl -e 'my %skip = map { $$_ => 1 } split /,/, $$ENV{SKIP}; my %seen; for my $$dep (split /,/, $$ENV{EXTRA}) { next unless length $$dep; my ($$n, $$v, $$r) = split /:/, $$dep; next if $$skip{$$n}; $$seen{"$$n\t$$v\t$$r"} = 1 if defined $$r; } while (<>) { next unless /^\s+(\S+)\s+(\S+)\s+(\d+)\s*\\?$$/; next if $$skip{$$1}; $$seen{"$$1\t$$2\t$$3"} = 1; } my @deps = sort keys %seen; print "MODCABAL_MANIFEST\t= \\\n"; for my $$i (0 .. $$#deps) { print "\t$$deps[$$i]"; print $$i == $$#deps ? "\n" : "\t\\\n"; }' \
		${WRKDIR}/simplexmq.smp.inc ${WRKDIR}/simplexmq.xftp.inc \
			> ${.CURDIR}/cabal.inc

.include "cabal.inc"

.include <bsd.port.mk>
