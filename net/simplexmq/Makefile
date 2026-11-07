COMMENT = SimpleX messaging protocol server and client library

DEBUG ?= 0

GH_ACCOUNT = simplex-chat
GH_PROJECT = simplexmq
GH_COMMIT = c1830fb2dbf5a1a5cc3b56c6c65ef911a622ae6d

V = 7.1.0.17
DISTNAME = ${GH_PROJECT}-${V}
DISTFILES = ${GH_DISTFILE}
SITES = ${SITES_GITHUB}
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

DIST_TUPLE += github simplex-chat aeson \
		aab7b5a14d6c5ea64c64dcaee418de1bb00dcc2b ../aeson
DIST_TUPLE += github simplex-chat hs-socks \
		a30cc7a79a08d8108316094f8f2f82a0c5e1ac51 ../hs-socks
DIST_TUPLE += github simplex-chat direct-sqlcipher \
		2330df3dc8c4b660674d3c02d76bb86f66c2abee ../direct-sqlcipher
DIST_TUPLE += github simplex-chat sqlcipher-simple \
		a46bd361a19376c5211f1058908fc0ae6bf42446 ../sqlcipher-simple
DIST_TUPLE += github yesodweb wai \
		ec5e017d896a78e787a5acea62b37a4e677dec2e ../yesod-wai
DIST_TUPLE += github simplex-chat wai \
		63667cb577d09c967ddcd945e42c324872dfeb7d ../simplex-wai
DIST_TUPLE += github supranational blst \
		db3defd0d501cc2bb1cdd59cb955d1a421821441 cbits/blst
DIST_TUPLE += github simplex-chat libbbs \
		59a0f4bf32e195cb6883de8374825c0f4764c717 cbits/libbbs

CATEGORIES = net
HOMEPAGE = https://simplex.chat/

MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# GNU Affero General Public License v3.0 only (AGPL-3.0-only)
PERMIT_PACKAGE = Yes

WANTLIB = c crypto ffi gmp iconv m pthread sqlcipher util z zstd

MODULES = devel/cabal
MODCABAL_STEM = simplexmq
MODCABAL_VERSION = 7.1.0.17
MODCABAL_EXECUTABLES = smp-server xftp-server

.if ${DEBUG} == 1
MODCABAL_BUILD_ARGS = -v2
.endif

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
CABAL_INC_HOME ?= ${WRKDIR}/.cabal-inc-home
CABAL_INC_ENV = \
	CABAL_INC_HOME=${CABAL_INC_HOME} LOCALBASE=${LOCALBASE} \
	WRKDIR=${WRKDIR} WRKBUILD=${WRKBUILD} PORTDIR=${.CURDIR} \
	FILESDIR=${FILESDIR} \
	MODCABAL_STEM=${MODCABAL_STEM} \
	MODCABAL_VERSION=${MODCABAL_VERSION} \
	SIMPLEXMQ_CABAL_PACKAGE_PATHS='${SIMPLEXMQ_CABAL_PACKAGE_PATHS}' \
	CABAL_INC_SKIP='${CABAL_INC_SKIP}' \
	CABAL_INC_EXTRA='${CABAL_INC_EXTRA}' \
	INSTALL_DATA_DIR="${INSTALL_DATA_DIR}"
CABAL_INC_SKIP = aeson,socks,direct-sqlcipher,sqlcipher-simple,warp-tls,warp
CABAL_INC_EXTRA = wai-app-static:3.2.1:0,wai-extra:3.1.18:0,yaml:0.11.11.2:0
SIMPLEXMQ_CABAL_PACKAGES = \
	'packages: ${WRKDIR}/aeson/aeson.cabal' \
	'packages: ${WRKDIR}/hs-socks/socks.cabal' \
	'packages: ${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal' \
	'packages: ${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal' \
	'packages: ${WRKDIR}/yesod-wai/warp-tls/warp-tls.cabal' \
	'packages: ${WRKDIR}/simplex-wai/warp/warp.cabal'
SIMPLEXMQ_CABAL_PACKAGE_PATHS = \
	${WRKDIR}/aeson/aeson.cabal \
	${WRKDIR}/hs-socks/socks.cabal \
	${WRKDIR}/direct-sqlcipher/direct-sqlcipher.cabal \
	${WRKDIR}/sqlcipher-simple/sqlcipher-simple.cabal \
	${WRKDIR}/yesod-wai/warp-tls/warp-tls.cabal \
	${WRKDIR}/simplex-wai/warp/warp.cabal
SIMPLEXMQ_CABAL_COMMON_OPTIONS = \
	'constraints: network ==${NETWORK_V}, http2 ==${HTTP2_V}, tls ==${TLS_V}' \
	'package simplexmq' \
	'    flags: +use_crypton -swift -client_postgres -server_postgres -client_library' \
	'package direct-sqlcipher' \
	'    flags: +systemlib' \
	'package zstd' \
	'    flags: -standalone' \
	'package *' \
	'    ghc-options: -w -optP-Wno-expansion-to-defined'
SIMPLEXMQ_CABAL_TEST_OPTIONS = \
	'package *' \
	'    tests: False' \
	'package simplexmq' \
	'    tests: True'
AESON_PATCHES = \
	patch-aeson_cabal \
	patch-src_Data_Aeson_Types_FromJSON_hs \
	patch-src_Data_Aeson_KeyMap_hs
CRYPTOSTORE_PATCHES = \
	patch-src_Crypto_Store_CMS_Algorithms_hs
WARP_PATCHES = \
	patch-warp_cabal \
	patch-Network_Wai_Handler_Warp_FileInfoCache_hs \
	patch-Network_Wai_Handler_Warp_HTTP2_hs
SIMPLEXMQ_TEST_OPTIONS ?=
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

post-patch:
	env WRKDIR=${WRKDIR} WRKSRC=${WRKSRC} FILESDIR=${FILESDIR} \
		LOCALBASE=${LOCALBASE} \
		INSTALL_DATA="${INSTALL_DATA}" \
		INSTALL_DATA_DIR="${INSTALL_DATA_DIR}" \
		SIMPLEXMQ_CABAL_PACKAGE_PATHS='${SIMPLEXMQ_CABAL_PACKAGE_PATHS}' \
		AESON_PATCHES='${AESON_PATCHES}' \
		CRYPTOSTORE_PATCHES='${CRYPTOSTORE_PATCHES}' \
		CRYPTOSTORE_V=${CRYPTOSTORE_V} \
		WARP_PATCHES='${WARP_PATCHES}' \
		TLS_PATCHES='${TLS_PATCHES}' TLS_V=${TLS_V} \
		HTTP2_PATCHES='${HTTP2_PATCHES}' HTTP2_V=${HTTP2_V} \
		NETWORK_V=${NETWORK_V} UNIX_TIME_V=${UNIX_TIME_V} \
		ENTROPY_V=${ENTROPY_V} \
		sh ${FILESDIR}/post-patch.sh
	printf '%s\n' \
		${SIMPLEXMQ_CABAL_PACKAGES} \
		${SIMPLEXMQ_CABAL_COMMON_OPTIONS} \
		>> ${WRKSRC}/cabal.project.local

cabal-inc: patch
	printf '%s\n' \
		${SIMPLEXMQ_CABAL_PACKAGES} \
		${SIMPLEXMQ_CABAL_COMMON_OPTIONS} \
		> ${WRKSRC}/cabal.project.local
	env ${CABAL_INC_ENV} sh ${FILESDIR}/cabal-inc.sh build
	printf '%s\n' \
		${SIMPLEXMQ_CABAL_TEST_OPTIONS} \
		>> ${WRKSRC}/cabal.project.local
	env ${CABAL_INC_ENV} sh ${FILESDIR}/cabal-inc.sh test
	env ${CABAL_INC_ENV} sh ${FILESDIR}/cabal-inc.sh merge

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/${PKGSTEM}
	${INSTALL_DATA} ${PKGDIR}/LICENSE \
		${PREFIX}/share/doc/${PKGSTEM}/LICENSE
	${INSTALL_MAN} ${FILESDIR}/smp-server.1 \
		${PREFIX}/man/man1/smp-server.1
	${INSTALL_MAN} ${FILESDIR}/xftp-server.1 \
		${PREFIX}/man/man1/xftp-server.1

do-test:
	# Keep default-temp XFTP probes and capture files inside make clean's scope.
	mkdir -p -m 700 ${WRKDIR}/test-tmp
	sh ${FILESDIR}/check-package-paths.sh ${SIMPLEXMQ_CABAL_PACKAGE_PATHS}
	printf '%s\n' \
		${SIMPLEXMQ_CABAL_PACKAGES} \
		${SIMPLEXMQ_CABAL_COMMON_OPTIONS} \
		${SIMPLEXMQ_CABAL_TEST_OPTIONS} \
		>> ${WRKSRC}/cabal.project.local
	# Invoke Cabal directly so the module wrapper does not reset HOME.
	cd ${WRKBUILD} && exec ${SETENV} ${MAKE_ENV} \
		TMPDIR=${WRKDIR}/test-tmp \
		HOME=${CABAL_INC_HOME} \
		CABAL_DIR=${CABAL_INC_HOME}/.cabal \
		XDG_CACHE_HOME=${CABAL_INC_HOME}/.cache \
		XDG_CONFIG_HOME=${CABAL_INC_HOME}/.config \
		${LOCALBASE}/bin/cabal v2-test --offline --disable-benchmarks \
		--test-show-details=streaming \
		-w ${LOCALBASE}/bin/ghc \
		-j${MAKE_JOBS} \
		--flags="${MODCABAL_FLAGS}" ${MODCABAL_BUILD_ARGS} \
		--test-options=${SIMPLEXMQ_TEST_OPTIONS:Q} \
		test:simplexmq-test

# Keep the local harness entry point used by `make do-tests`.
do-tests: test

.include "cabal.inc"

.include <bsd.port.mk>
