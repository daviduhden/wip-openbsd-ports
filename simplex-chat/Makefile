COMMENT = Private and encrypted chat platform (terminal client)

DEBUG ?= 0

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplex-chat
GH_TAGNAME = v6.5.5

V = 6.5.5.0
DISTNAME = ${GH_PROJECT}-${V}
DISTFILES = ${GH_DISTFILE}
SITES = ${SITES_GITHUB}
WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_TAGNAME:S/^v//}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

DIST_TUPLE += github simplex-chat simplexmq \
		376d6a261a1074717aed65ad97bb6f2a9532011b ../simplexmq
DIST_TUPLE += github simplex-chat hs-socks \
		a30cc7a79a08d8108316094f8f2f82a0c5e1ac51 ../hs-socks
DIST_TUPLE += github simplex-chat direct-sqlcipher \
		f814ee68b16a9447fbb467ccc8f29bdd3546bfd9 ../direct-sqlcipher
DIST_TUPLE += github simplex-chat sqlcipher-simple \
		a46bd361a19376c5211f1058908fc0ae6bf42446 ../sqlcipher-simple
DIST_TUPLE += github simplex-chat aeson \
		aab7b5a14d6c5ea64c64dcaee418de1bb00dcc2b ../aeson
DIST_TUPLE += github simplex-chat haskell-terminal \
		f708b00009b54890172068f168bf98508ffcd495 ../haskell-terminal
DIST_TUPLE += github simplex-chat android-support \
		9aa09f148089d6752ce563b14c2df1895718d806 ../android-support
DIST_TUPLE += github simplex-chat zip \
		2eff156c3aac389e35d38bf10a52733d7061640a ../zip

CATEGORIES = net
HOMEPAGE = https://simplex.chat/

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# AGPL-3
PERMIT_PACKAGE = Yes

WANTLIB = ${COMPILER_LIBCXX} c crypto ffi gmp iconv m pthread sqlcipher util z zstd

MODULES = devel/cabal
MODCABAL_STEM = simplex-chat
MODCABAL_VERSION = ${V}
MODCABAL_EXECUTABLES = simplex-chat

.if ${DEBUG} == 1
MODCABAL_BUILD_ARGS = -v2
.endif

NETWORK_V = 3.2.8.0
UNIX_TIME_V = 0.5.0
CRYPTOSTORE_V = 0.5.0.0
CABAL_INC_HOME ?= ${WRKDIR}/.cabal-inc-home
CABAL_INC_SKIP = simplexmq,aeson,socks,direct-sqlcipher,sqlcipher-simple,terminal,android-support,zip
CABAL_INC_EXTRA = yaml:0.11.11.2:0
AESON_PATCHES = \
	patch-aeson_cabal \
	patch-src_Data_Aeson_Types_FromJSON_hs \
	patch-src_Data_Aeson_KeyMap_hs
CRYPTOSTORE_PATCHES = \
	patch-cryptostore_cabal \
	patch-src_Crypto_Store_Util_hs
SIMPLEXMQ_PATCHES = \
	patch-simplexmq_cabal \
	patch-src_Simplex_Messaging_Agent_Store_SQLite_Migrations_agent_schema_sql \
	patch-src_Simplex_Messaging_Server_MsgStore_Journal_hs \
	patch-src_Simplex_Messaging_Transport_hs \
	patch-src_Simplex_Messaging_Transport_Client_hs \
	patch-src_Simplex_Messaging_Transport_KeepAlive_hs \
	patch-src_Simplex_Messaging_Transport_Server_hs

LIB_DEPENDS = databases/sqlcipher \
			archivers/zstd

RUN_DEPENDS = databases/sqlcipher \
			archivers/zstd

post-patch:
	printf '%s\n' \
		'packages: ${WRKDIR}/simplexmq/simplexmq.cabal' \
		'packages: ${WRKDIR}/hs-socks/socks.cabal' \
		'packages: ${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal' \
		'packages: ${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal' \
		'packages: ${WRKDIR}/aeson/aeson.cabal' \
		'packages: ${WRKDIR}/haskell-terminal/terminal.cabal' \
		'packages: ${WRKDIR}/android-support/android-support.cabal' \
		'packages: ${WRKDIR}/zip/zip.cabal' \
		'package simplexmq' \
		'    flags: +client_library' \
		'package *' \
		'    ghc-options: -w -optP-Wno-expansion-to-defined' \
		>> ${WRKSRC}/cabal.project.local
.for _p in ${SIMPLEXMQ_PATCHES}
	patch -d ${WRKDIR}/simplexmq -p0 < ${FILESDIR}/${_p}
.endfor
.for _p in ${AESON_PATCHES}
	patch -d ${WRKDIR}/aeson -p0 < ${FILESDIR}/${_p}
.endfor
.for _p in ${CRYPTOSTORE_PATCHES}
	if [ -d ${WRKDIR}/cryptostore-${CRYPTOSTORE_V} ]; then \
		patch -d ${WRKDIR}/cryptostore-${CRYPTOSTORE_V} -p0 \
			< ${FILESDIR}/${_p}; \
	fi
.endfor
	if [ -f ${WRKDIR}/network-${NETWORK_V}/network.cabal ]; then \
		patch -d ${WRKDIR}/network-${NETWORK_V} -p0 \
			< ${FILESDIR}/patch-network_cabal; \
		${INSTALL_DATA_DIR} ${WRKDIR}/network-${NETWORK_V}/include; \
		${INSTALL_DATA} ${FILESDIR}/HsNetworkConfig.h \
			${WRKDIR}/network-${NETWORK_V}/include/HsNetworkConfig.h; \
	fi
	if [ -f ${WRKDIR}/unix-time-${UNIX_TIME_V}/unix-time.cabal ]; then \
		patch -d ${WRKDIR}/unix-time-${UNIX_TIME_V} -p0 \
			< ${FILESDIR}/patch-unix-time_cabal; \
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
	printf '%s\n' \
		'packages: ${WRKDIR}/simplexmq/simplexmq.cabal' \
		'packages: ${WRKDIR}/hs-socks/socks.cabal' \
		'packages: ${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal' \
		'packages: ${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal' \
		'packages: ${WRKDIR}/aeson/aeson.cabal' \
		'packages: ${WRKDIR}/haskell-terminal/terminal.cabal' \
		'packages: ${WRKDIR}/android-support/android-support.cabal' \
		'packages: ${WRKDIR}/zip/zip.cabal' \
		'package simplexmq' \
		'    flags: +client_library' \
		'package *' \
		'    ghc-options: -w -optP-Wno-expansion-to-defined' \
		> ${WRKSRC}/cabal.project.local
	cd ${WRKBUILD} && env HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal v2-build --dry-run \
		-w ${LOCALBASE}/bin/ghc \
		--disable-benchmarks --disable-tests \
		exe:simplex-chat
	cd ${WRKBUILD} && env HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal-bundler --openbsd \
		--plan dist-newstyle/cache/plan.json \
		--executable simplex-chat \
		${MODCABAL_STEM}-${MODCABAL_VERSION} \
		> ${WRKDIR}/simplex-chat.raw.inc
	env SKIP=${CABAL_INC_SKIP} EXTRA=${CABAL_INC_EXTRA} \
		perl -e 'my %skip = map { $$_ => 1 } split /,/, $$ENV{SKIP}; my %seen; for my $$dep (split /,/, $$ENV{EXTRA}) { next unless length $$dep; my ($$n, $$v, $$r) = split /:/, $$dep; next if $$skip{$$n}; $$seen{"$$n\t$$v\t$$r"} = 1 if defined $$r; } while (<>) { next unless /^\s+(\S+)\s+(\S+)\s+(\d+)\s*\\?$$/; my ($$n, $$v, $$r) = ($$1, $$2, $$3); next if $$skip{$$n}; $$seen{"$$n\t$$v\t$$r"} = 1; } my @deps = sort keys %seen; print "MODCABAL_MANIFEST\t= \\\n"; for my $$i (0 .. $$#deps) { print "\t$$deps[$$i]"; print $$i == $$#deps ? "\n" : "\t\\\n"; }' \
		${WRKDIR}/simplex-chat.raw.inc \
			> ${.CURDIR}/cabal.inc

.include "cabal.inc"

.include <bsd.port.mk>
