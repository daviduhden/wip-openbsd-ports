COMMENT = Private and encrypted chat platform (terminal client)

DEBUG ?= 0

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplex-chat
GH_TAGNAME = v7.1.0

V = 7.1.0
DISTNAME = ${GH_PROJECT}-${V}
DISTFILES = ${GH_DISTFILE}
SITES = ${SITES_GITHUB}
WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_TAGNAME:S/^v//}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

DIST_TUPLE += github simplex-chat simplexmq \
		a0eec7104c706ab0dab2ad604f280a7130f7a22c ../simplexmq
DIST_TUPLE += github supranational blst \
		db3defd0d501cc2bb1cdd59cb955d1a421821441 ../simplexmq/cbits/blst
DIST_TUPLE += github simplex-chat libbbs \
		59a0f4bf32e195cb6883de8374825c0f4764c717 ../simplexmq/cbits/libbbs
DIST_TUPLE += github simplex-chat hs-socks \
		a30cc7a79a08d8108316094f8f2f82a0c5e1ac51 ../hs-socks
DIST_TUPLE += github simplex-chat direct-sqlcipher \
		2330df3dc8c4b660674d3c02d76bb86f66c2abee ../direct-sqlcipher
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
DIST_TUPLE += github simplex-chat hs-jpeg-turbo \
		d0a4d954038ee5bcb5c4dc9372a6fb0b05fed77c ../hs-jpeg-turbo
DIST_TUPLE += github simplex-chat JuicyPixels-stbir \
		e0090e14f6348a33b53c11b377cb69df766b02b4 ../JuicyPixels-stbir
DIST_TUPLE += github mozilla mozjpeg \
		08265790774cd0714832c9e675522acbe5581437 \
		../hs-jpeg-turbo/jpeg-turbo/cbits/mozjpeg
DIST_TUPLE += github randy408 libspng \
		fb768002d4288590083a476af628e51c3f1d47cd \
		../hs-jpeg-turbo/JuicyPixels-spng/cbits/libspng
DIST_TUPLE += github richgel999 miniz \
		77d0dce8627735138c51770d1799a1ef48f2117d \
		../hs-jpeg-turbo/JuicyPixels-spng/cbits/miniz
DIST_TUPLE += github nothings stb \
		1ee679ca2ef753a528db5ba6801e1067b40481b8 ../JuicyPixels-stbir/cbits/stb

CATEGORIES = net
HOMEPAGE = https://simplex.chat/

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# GNU Affero General Public License v3.0 only (AGPL-3.0-only)
PERMIT_PACKAGE = Yes

WANTLIB = c crypto ffi gmp iconv m pthread sqlcipher util z zstd

MODULES = devel/cabal
MODCABAL_STEM = simplex-chat
MODCABAL_VERSION = 7.1.0.19
MODCABAL_EXECUTABLES = simplex-chat

.if ${DEBUG} == 1
MODCABAL_BUILD_ARGS = -v2
.endif

CABAL_INC_HOME ?= ${WRKDIR}/.cabal-inc-home
CABAL_INC_ENV = \
	CABAL_INC_HOME=${CABAL_INC_HOME} LOCALBASE=${LOCALBASE} \
	WRKDIR=${WRKDIR} WRKBUILD=${WRKBUILD} PORTDIR=${.CURDIR} \
	FILESDIR=${FILESDIR} \
	MODCABAL_STEM=${MODCABAL_STEM} \
	MODCABAL_VERSION=${MODCABAL_VERSION} \
	CHAT_CABAL_PACKAGE_PATHS='${CHAT_CABAL_PACKAGE_PATHS}' \
	CABAL_INC_SKIP='${CABAL_INC_SKIP}' \
	CABAL_INC_EXTRA='${CABAL_INC_EXTRA}' \
	INSTALL_DATA_DIR="${INSTALL_DATA_DIR}"
CABAL_INC_SKIP = simplexmq,aeson,socks,direct-sqlcipher,sqlcipher-simple,terminal,android-support,zip,jpeg-turbo,JuicyPixels-jpeg-turbo,JuicyPixels-spng,JuicyPixels-stbir
CABAL_INC_EXTRA = yaml:0.11.11.2:0
NETWORK_V = 3.2.9.0
HTTP2_V = 5.4.4
HTTP2_PATCHES = \
	patch-http2_Network_HTTP2_Client_Run_hs \
	patch-http2_Network_HTTP2_H2_Stream_hs \
	patch-http2_Network_HTTP2_Server_Worker_hs
TLS_V = 2.4.3
TLS_PATCHES = \
	patch-tls_Network_TLS_Context_hs \
	patch-tls_Network_TLS_Context_Internal_hs \
	patch-tls_Network_TLS_Core_hs \
	patch-tls_Network_TLS_Extra_Cipher_hs \
	patch-tls_test_HandshakeSpec_hs \
	patch-tls_test_Run_hs
UNIX_TIME_V = 0.5.0
CRYPTOSTORE_V = 0.6.0.0
ENTROPY_V = 0.4.1.11
WITHERABLE_V = 0.5
WITHERABLE_TARBALL = ${DISTDIR}/hackage/witherable-${WITHERABLE_V}.tar.gz
WITHERABLE_DIR = ${WRKDIR}/witherable-${WITHERABLE_V}
DISTFILES.hs += {witherable-${WITHERABLE_V}/}witherable-${WITHERABLE_V}.tar.gz
CHAT_CABAL_PACKAGES = \
	'packages: ${WRKDIR}/simplexmq/simplexmq.cabal' \
	'packages: ${WRKDIR}/hs-socks/socks.cabal' \
	'packages: ${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal' \
	'packages: ${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal' \
	'packages: ${WRKDIR}/aeson/aeson.cabal' \
	'packages: ${WRKDIR}/witherable-${WITHERABLE_V}/witherable.cabal' \
	'packages: ${WRKDIR}/haskell-terminal/terminal.cabal' \
	'packages: ${WRKDIR}/android-support/android-support.cabal' \
	'packages: ${WRKDIR}/zip/zip.cabal' \
	'packages: ${WRKDIR}/hs-jpeg-turbo/JuicyPixels-jpeg-turbo/JuicyPixels-jpeg-turbo.cabal' \
	'packages: ${WRKDIR}/hs-jpeg-turbo/JuicyPixels-spng/JuicyPixels-spng.cabal' \
	'packages: ${WRKDIR}/hs-jpeg-turbo/jpeg-turbo/jpeg-turbo.cabal' \
	'packages: ${WRKDIR}/JuicyPixels-stbir/JuicyPixels-stbir.cabal'
CHAT_CABAL_PACKAGE_PATHS = \
	${WRKDIR}/simplexmq/simplexmq.cabal \
	${WRKDIR}/hs-socks/socks.cabal \
	${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal \
	${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal \
	${WRKDIR}/aeson/aeson.cabal \
	${WRKDIR}/witherable-${WITHERABLE_V}/witherable.cabal \
	${WRKDIR}/haskell-terminal/terminal.cabal \
	${WRKDIR}/android-support/android-support.cabal \
	${WRKDIR}/zip/zip.cabal \
	${WRKDIR}/hs-jpeg-turbo/JuicyPixels-jpeg-turbo/JuicyPixels-jpeg-turbo.cabal \
	${WRKDIR}/hs-jpeg-turbo/JuicyPixels-spng/JuicyPixels-spng.cabal \
	${WRKDIR}/hs-jpeg-turbo/jpeg-turbo/jpeg-turbo.cabal \
	${WRKDIR}/JuicyPixels-stbir/JuicyPixels-stbir.cabal
CHAT_CABAL_COMMON_OPTIONS = \
	'constraints: network ==${NETWORK_V}, http2 ==${HTTP2_V}, tls ==${TLS_V}' \
	'package simplex-chat' \
	'    flags: -swift -client_postgres -client_library' \
	'package simplexmq' \
	'    flags: +use_crypton -swift -client_postgres -server_postgres' \
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
	patch-src_Crypto_Store_CMS_Algorithms_hs
SIMPLEXMQ_PATCHES = \
	patch-simplexmq_cabal \
	patch-src_Simplex_FileTransfer_Agent_hs \
	patch-src_Simplex_FileTransfer_Server_Main_hs \
	patch-src_Simplex_FileTransfer_Transport_hs \
	patch-src_Simplex_Messaging_Agent_hs \
	patch-src_Simplex_Messaging_Agent_Client_hs \
	patch-src_Simplex_Messaging_Agent_Env_SQLite_hs \
	patch-src_Simplex_Messaging_Agent_Store_AgentStore_hs \
	patch-src_Simplex_Messaging_Agent_Store_SQLite_hs \
	patch-src_Simplex_Messaging_Agent_Store_SQLite_Common_hs \
	patch-src_Simplex_Messaging_Agent_Store_SQLite_Migrations_agent_schema_sql \
	patch-src_Simplex_Messaging_Client_hs \
	patch-src_Simplex_Messaging_Client_Agent_hs \
	patch-src_Simplex_Messaging_Crypto_hs \
	patch-src_Simplex_Messaging_Crypto_Lazy_hs \
	patch-src_Simplex_Messaging_Notifications_Server_Main_hs \
	patch-src_Simplex_Messaging_Notifications_Server_hs \
	patch-src_Simplex_Messaging_Server_CLI_hs \
	patch-src_Simplex_Messaging_Server_hs \
	patch-src_Simplex_Messaging_Server_Web_hs \
	patch-src_Simplex_Messaging_Transport_hs \
	patch-src_Simplex_Messaging_Transport_Client_hs \
	patch-src_Simplex_Messaging_Transport_HTTP2_hs \
	patch-src_Simplex_Messaging_Transport_HTTP2_Client_hs \
	patch-src_Simplex_Messaging_Transport_HTTP2_Server_hs \
	patch-src_Simplex_Messaging_Transport_KeepAlive_hs \
	patch-src_Simplex_Messaging_Transport_Server_hs \
	patch-src_Simplex_Messaging_Util_hs \
	patch-src_Simplex_RemoteControl_Client_hs \
	patch-src_Simplex_RemoteControl_Discovery_hs \
	patch-src_Simplex_RemoteControl_Discovery_Multicast_hsc

LIB_DEPENDS = archivers/zstd \
			converters/libiconv \
			databases/sqlcipher \
			devel/gmp \
			devel/libffi

# ghc and cabal-install also come from devel/cabal, with the same version
# constraints; cabal-bundler generates the dependency manifest from the
# build plan in the cabal-inc target.
BUILD_DEPENDS = converters/dos2unix \
		devel/cabal-bundler \
		devel/cabal-install>=3.12.0.0 \
		lang/ghc>=9.8.3
TEST_DEPENDS = databases/sqlite3

# Hspec selection and diagnostic options for targeted ports test runs.
SIMPLEX_TEST_OPTIONS ?=
SIMPLEX_TEST_OUTPUT ?= 0

post-patch:
	env WRKDIR=${WRKDIR} WRKSRC=${WRKSRC} FILESDIR=${FILESDIR} \
		LOCALBASE=${LOCALBASE} \
		INSTALL_DATA="${INSTALL_DATA}" \
		INSTALL_DATA_DIR="${INSTALL_DATA_DIR}" \
		CHAT_CABAL_PACKAGE_PATHS='${CHAT_CABAL_PACKAGE_PATHS}' \
		SIMPLEXMQ_PATCHES='${SIMPLEXMQ_PATCHES}' \
		AESON_PATCHES='${AESON_PATCHES}' \
		CRYPTOSTORE_PATCHES='${CRYPTOSTORE_PATCHES}' \
		CRYPTOSTORE_V=${CRYPTOSTORE_V} \
		TLS_PATCHES='${TLS_PATCHES}' TLS_V=${TLS_V} \
		HTTP2_PATCHES='${HTTP2_PATCHES}' HTTP2_V=${HTTP2_V} \
		NETWORK_V=${NETWORK_V} UNIX_TIME_V=${UNIX_TIME_V} \
		ENTROPY_V=${ENTROPY_V} \
		WITHERABLE_DIR=${WITHERABLE_DIR} \
		WITHERABLE_TARBALL=${WITHERABLE_TARBALL} \
		TAR=${TAR} \
		sh ${FILESDIR}/post-patch.sh
	printf '%s\n' \
		'allow-newer: *' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_BUILD_OPTIONS} \
		>> ${WRKSRC}/cabal.project.local

cabal-inc: patch
	printf '%s\n' \
		'allow-newer: *' \
		'packages: .' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_BUILD_OPTIONS} \
		> ${WRKSRC}/cabal.project.local
	env ${CABAL_INC_ENV} sh ${FILESDIR}/cabal-inc.sh build
	# Test builds need simplexmq to expose the server modules imported by tests.
	printf '%s\n' \
		'allow-newer: *' \
		'packages: .' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_TEST_OPTIONS} \
		> ${WRKSRC}/cabal.project.local
	env ${CABAL_INC_ENV} sh ${FILESDIR}/cabal-inc.sh test
	env ${CABAL_INC_ENV} sh ${FILESDIR}/cabal-inc.sh merge

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/${PKGSTEM}
	${INSTALL_DATA} ${PKGDIR}/LICENSE \
		${PREFIX}/share/doc/${PKGSTEM}/LICENSE
	${INSTALL_MAN} ${FILESDIR}/simplex-chat.1 \
		${PREFIX}/man/man1/simplex-chat.1

do-test:
	# Keep simplexmq unflagged here so the test suite can import its server APIs.
	# Shared XFTP probes must not leave received files in the global /tmp.
	mkdir -p -m 700 ${WRKDIR}/test-tmp
	sh ${FILESDIR}/check-package-paths.sh ${CHAT_CABAL_PACKAGE_PATHS}
	# Cabal keeps the first value of a repeated per-package flag, so rewrite
	# the build-only +client_library stanza instead of appending a new one.
	sed 's/^    flags: +client_library$$/    flags: -client_library/' \
		${WRKSRC}/cabal.project.local > ${WRKSRC}/cabal.project.local.new
	mv ${WRKSRC}/cabal.project.local.new ${WRKSRC}/cabal.project.local
	# Preserve the local dependency paths and options added by devel/cabal.
	printf '%s\n' \
		${CHAT_CABAL_PACKAGES} \
		${CHAT_CABAL_COMMON_OPTIONS} \
		${CHAT_CABAL_TEST_OPTIONS} \
		>> ${WRKSRC}/cabal.project.local
	# Invoke Cabal directly: _MODCABAL_CABAL would reset this environment.
	# SIMPLEX_UPDATE_QUERY_PLANS=1 regenerates the platform-specific query
	# plans instead of asserting them (see tests/SchemaDump.hs); run once and
	# copy the generated files into files/ to enable the assertion on
	# subsequent runs.
	_plans=""; \
	if [ -f ${FILESDIR}/chat_query_plans.txt ] && [ -f ${FILESDIR}/agent_query_plans.txt ]; then \
		_plans=1; \
	fi; \
	cd ${WRKBUILD} && exec ${SETENV} ${MAKE_ENV} \
		SIMPLEX_TEST_OUTPUT=${SIMPLEX_TEST_OUTPUT} \
		SIMPLEX_QUERY_PLANS_PLATFORM=$$_plans \
		SIMPLEX_UPDATE_QUERY_PLANS=${SIMPLEX_UPDATE_QUERY_PLANS} \
		TMPDIR=${WRKDIR}/test-tmp \
		HOME=${WRKDIR} \
		CABAL_DIR=${WRKDIR}/.cabal \
		XDG_CACHE_HOME=${WRKDIR}/.cache \
		XDG_CONFIG_HOME=${WRKDIR}/.config \
		${LOCALBASE}/bin/cabal v2-test --offline --disable-benchmarks \
		--test-show-details=streaming \
		--test-options=${SIMPLEX_TEST_OPTIONS:Q} \
		-w ${LOCALBASE}/bin/ghc \
		-j${MAKE_JOBS} \
		--flags="${MODCABAL_FLAGS}" ${MODCABAL_BUILD_ARGS} \
		test:simplex-chat-test

# Keep the local harness entry point used by `make do-tests`.
do-tests: test

.include "cabal.inc"

.include <bsd.port.mk>
