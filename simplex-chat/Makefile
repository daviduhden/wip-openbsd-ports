COMMENT = Private and encrypted chat platform (terminal client)

DEBUG ?= 0

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplex-chat
GH_TAGNAME = v7.0.0

V = 7.0.0.11
DISTNAME = ${GH_PROJECT}-${V}
DISTFILES = ${GH_DISTFILE}
SITES = ${SITES_GITHUB}
WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_TAGNAME:S/^v//}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

DIST_TUPLE += github simplex-chat simplexmq \
		efaad8e73436d60f5052f07dda6b71151ad5039b ../simplexmq
DIST_TUPLE += github supranational blst \
		db3defd0d501cc2bb1cdd59cb955d1a421821441 ../simplexmq/cbits/blst
DIST_TUPLE += github simplex-chat libbbs \
		59a0f4bf32e195cb6883de8374825c0f4764c717 ../simplexmq/cbits/libbbs
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

# GNU Affero General Public License v3.0 only (AGPL-3.0-only)
PERMIT_PACKAGE = Yes

WANTLIB = c crypto ffi gmp iconv m pthread sqlcipher util z zstd

MODULES = devel/cabal
MODCABAL_STEM = simplex-chat
MODCABAL_VERSION = ${V}
MODCABAL_EXECUTABLES = simplex-chat

.if ${DEBUG} == 1
MODCABAL_BUILD_ARGS = -v2
.endif

CABAL_INC_HOME ?= ${WRKDIR}/.cabal-inc-home
CABAL_INC_SKIP = simplexmq,aeson,socks,direct-sqlcipher,sqlcipher-simple,terminal,android-support,zip
CABAL_INC_EXTRA = yaml:0.11.11.2:0
NETWORK_V = 3.2.8.0
UNIX_TIME_V = 0.5.0
CRYPTOSTORE_V = 0.5.0.0
ENTROPY_V = 0.4.1.11
WITHERABLE_V = 0.5
WITHERABLE_TARBALL = ${DISTDIR}/hackage/witherable-${WITHERABLE_V}.tar.gz
WITHERABLE_DIR = ${WRKDIR}/witherable-${WITHERABLE_V}
CHAT_CABAL_PACKAGES = \
	'packages: ${WRKDIR}/simplexmq/simplexmq.cabal' \
	'packages: ${WRKDIR}/hs-socks/socks.cabal' \
	'packages: ${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal' \
	'packages: ${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal' \
	'packages: ${WRKDIR}/aeson/aeson.cabal' \
	'packages: ${WRKDIR}/witherable-${WITHERABLE_V}/witherable.cabal' \
	'packages: ${WRKDIR}/haskell-terminal/terminal.cabal' \
	'packages: ${WRKDIR}/android-support/android-support.cabal' \
	'packages: ${WRKDIR}/zip/zip.cabal'
CHAT_CABAL_PACKAGE_PATHS = \
	${WRKDIR}/simplexmq/simplexmq.cabal \
	${WRKDIR}/hs-socks/socks.cabal \
	${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal \
	${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal \
	${WRKDIR}/aeson/aeson.cabal \
	${WRKDIR}/witherable-${WITHERABLE_V}/witherable.cabal \
	${WRKDIR}/haskell-terminal/terminal.cabal \
	${WRKDIR}/android-support/android-support.cabal \
	${WRKDIR}/zip/zip.cabal
CHAT_CABAL_COMMON_OPTIONS = \
	'package direct-sqlcipher' \
	'    flags: +systemlib' \
	'package zstd' \
	'    flags: -standalone' \
	'package *' \
	'    ghc-options: -w -optP-Wno-expansion-to-defined'
CHAT_CABAL_BUILD_OPTIONS = \
	'package simplexmq' \
	'    flags: +client_library'
CHAT_CABAL_TEST_OPTIONS = \
	'package simplexmq' \
	'    flags: -client_library' \
	'package *' \
	'    tests: False' \
	'package simplex-chat' \
	'    tests: True'
AESON_PATCHES = \
	patch-aeson_cabal \
	patch-src_Data_Aeson_Types_FromJSON_hs \
	patch-src_Data_Aeson_KeyMap_hs
CRYPTOSTORE_PATCHES = \
	patch-cryptostore_cabal \
	patch-src_Crypto_Store_Cipher_RC2_Primitive_hs \
	patch-src_Crypto_Store_PKCS5_PBES1_hs \
	patch-src_Crypto_Store_Util_hs
SIMPLEXMQ_PATCHES = \
	patch-simplexmq_cabal \
	patch-src_Simplex_FileTransfer_Agent_hs \
	patch-src_Simplex_FileTransfer_Server_Main_hs \
	patch-src_Simplex_Messaging_Agent_hs \
	patch-src_Simplex_Messaging_Agent_Client_hs \
	patch-src_Simplex_Messaging_Agent_Env_SQLite_hs \
	patch-src_Simplex_Messaging_Agent_Store_SQLite_Migrations_agent_schema_sql \
	patch-src_Simplex_Messaging_Client_hs \
	patch-src_Simplex_Messaging_Client_Agent_hs \
	patch-src_Simplex_Messaging_Crypto_hs \
	patch-src_Simplex_Messaging_Notifications_Server_Main_hs \
	patch-src_Simplex_Messaging_Notifications_Server_hs \
	patch-src_Simplex_Messaging_Server_CLI_hs \
	patch-src_Simplex_Messaging_Server_MsgStore_Journal_hs \
	patch-src_Simplex_Messaging_Transport_hs \
	patch-src_Simplex_Messaging_Transport_Client_hs \
	patch-src_Simplex_Messaging_Transport_HTTP2_hs \
	patch-src_Simplex_Messaging_Transport_HTTP2_Client_hs \
	patch-src_Simplex_Messaging_Transport_HTTP2_Server_hs \
	patch-src_Simplex_Messaging_Transport_KeepAlive_hs \
	patch-src_Simplex_Messaging_Transport_Server_hs \
	patch-src_Simplex_RemoteControl_Client_hs \
	patch-src_Simplex_RemoteControl_Discovery_hs \
	patch-src_Simplex_RemoteControl_Discovery_Multicast_hsc

LIB_DEPENDS = archivers/zstd \
			converters/libiconv \
			databases/sqlcipher>=4.17.0 \
			devel/gmp \
			devel/libffi

BUILD_DEPENDS = converters/dos2unix

CHAT_CABAL_CHECK_PATHS = \
	for _pkg in ${CHAT_CABAL_PACKAGE_PATHS}; do \
		if [ ! -f "$$_pkg" ]; then \
			echo "missing cabal package: $$_pkg" >&2; \
			exit 1; \
		fi; \
	done

post-patch:
	# Normalize source to LF before applying patches.
	find ${WRKDIR} -type f \( -name '*.hs' -o -name '*.cabal' \
		-o -name '*.sql' -o -name '*.h' -o -name '*.c' \) \
		-exec ${LOCALBASE}/bin/dos2unix -q {} +
	patch -d ${WRKDIR}/direct-sqlcipher -p0 \
		< ${FILESDIR}/patch-direct-sqlcipher_cabal
	if [ ! -f ${WITHERABLE_DIR}/witherable.cabal ]; then \
		${TAR} -C ${WRKDIR} -xzf ${WITHERABLE_TARBALL}; \
	fi
	${CHAT_CABAL_CHECK_PATHS}
	printf '%s\n' \
		'allow-newer: *' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_BUILD_OPTIONS} \
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
	if [ -f ${WRKDIR}/entropy-${ENTROPY_V}/entropy.cabal ]; then \
		patch -d ${WRKDIR}/entropy-${ENTROPY_V} -p0 \
			< ${FILESDIR}/entropy-cabal.patch; \
		patch -d ${WRKDIR}/entropy-${ENTROPY_V} -p0 \
			< ${FILESDIR}/entropy-setup-openbsd.patch; \
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
	${CHAT_CABAL_CHECK_PATHS}
	printf '%s\n' \
		'allow-newer: *' \
		'packages: .' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_BUILD_OPTIONS} \
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
	# Test builds need simplexmq to expose the server modules imported by tests.
	${CHAT_CABAL_CHECK_PATHS}
	printf '%s\n' \
		'allow-newer: *' \
		'packages: .' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_TEST_OPTIONS} \
		> ${WRKSRC}/cabal.project.local
	cd ${WRKBUILD} && env HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal v2-test --dry-run \
		-w ${LOCALBASE}/bin/ghc \
		--disable-benchmarks \
		test:simplex-chat-test
	cp ${WRKBUILD}/dist-newstyle/cache/plan.json \
		${WRKDIR}/simplex-chat.test.plan.json
	env SKIP=${CABAL_INC_SKIP} EXTRA=${CABAL_INC_EXTRA} \
		perl ${FILESDIR}/cabal-deps-merge.pl \
		${WRKDIR}/simplex-chat.raw.inc \
			${WRKDIR}/simplex-chat.test.plan.json \
			> ${.CURDIR}/cabal.inc

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/${PKGSTEM}
	${INSTALL_DATA} ${PKGDIR}/LICENSE \
		${PREFIX}/share/doc/${PKGSTEM}/LICENSE
	${INSTALL_MAN} ${FILESDIR}/simplex-chat.1 \
		${PREFIX}/man/man1/simplex-chat.1

do-test:
	# Keep simplexmq unflagged here so the test suite can import its server APIs.
	${CHAT_CABAL_CHECK_PATHS}
	printf '%s\n' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_TEST_OPTIONS} \
		> ${WRKSRC}/cabal.project.local
	cd ${WRKBUILD} && exec ${SETENV} ${MAKE_ENV} \
		HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal \
		XDG_CACHE_HOME=${CABAL_INC_HOME}/.cache \
		XDG_CONFIG_HOME=${CABAL_INC_HOME}/.config \
		${_MODCABAL_CABAL} v2-test --offline --disable-benchmarks \
		-w ${LOCALBASE}/bin/ghc \
		-j${MAKE_JOBS} \
		--flags="${MODCABAL_FLAGS}" ${MODCABAL_BUILD_ARGS} \
		test:simplex-chat-test

# Keep the local harness entry point used by `make do-tests`.
do-tests: test

.include "cabal.inc"

.include <bsd.port.mk>
