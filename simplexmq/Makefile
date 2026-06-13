COMMENT = SimpleX messaging protocol server and client library
# Keep the main release version here; dependency pins live in the include
# files so they can be updated without touching the core port metadata.
V = 6.5.3.0
DISTNAME = simplexmq-${V}
WRKDIST = ${WRKDIR}/simplexmq-stable
WRKSRC = ${WRKDIST}
ONLY_FOR_ARCHS = amd64 arm64

CATEGORIES = net
FLAVORS = postgresql
PROJECT_FILE = cabal.project.local
.if !empty(FLAVOR:Mpostgresql)
PROJECT_FILE = cabal.project.local.postgresql
.endif

HOMEPAGE = https://simplex.chat/
# Upstream source tarballs come from GitHub; Hackage package pins are
# centralized in simplexmq.distfiles.inc for reviewability.
SITES = https://github.com/simplex-chat/ \
			https://github.com/yesodweb/
SITES.hs =		https://hackage.haskell.org/package/
SITES.warp-fork =	https://github.com/simplex-chat/wai/archive/
SITES.warp-tls-fork =	https://github.com/yesodweb/wai/archive/
DISTFILES = simplexmq-${V}${EXTRACT_SUFX}{simplexmq/archive/refs/heads/stable.tar.gz}
EXTRACT_ONLY = simplexmq-${V}${EXTRACT_SUFX}

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
	# Copy the port-local Cabal files first, then unpack and patch the source
	# trees that upstream expects to be present in cabal.project.
	mkdir -p ${WRKSRC}/apps/common/Web/static/.well-known
	cp ${FILESDIR}/cabal.project ${WRKSRC}/cabal.project
	cp ${FILESDIR}/cabal.project.local ${WRKSRC}/cabal.project.local
	if [ "${PROJECT_FILE}" = "cabal.project.local.postgresql" ]; then \
		cp ${FILESDIR}/cabal.project.local.postgresql ${WRKSRC}/cabal.project.local.postgresql; \
	fi
	cp ${FILESDIR}/simplexmq.cabal ${WRKSRC}/simplexmq.cabal
	tar -C ${WRKSRC} -xzf ${FULLDISTDIR}/splitmix-${SPLITMIX_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/entropy-${ENTROPY_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/unix-compat-${UNIX_COMPAT_V}.tar.gz
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/unix-compat-mktemp.patch
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/entropy-setup-openbsd.patch
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/entropy-getrandom.patch
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-fast-logger_cabal
	# fast-logger needs the source-side debounceThreadName fix for auto-update 0.1.6.
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-System_Log_FastLogger_LoggerSet_hs
	# fast-logger also drops updateThreadName on the same older auto-update API.
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-System_Log_FastLogger_Date_hs
	cp -R ${WRKDIR}/wai-${WARP_FORK_TAG}/warp ${WRKDIR}/warp-${WARP_V}
	cp -R ${WRKDIR}/wai-${WARP_TLS_FORK_TAG}/warp-tls ${WRKDIR}/warp-tls-${WARP_TLS_V}
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/bytestring-builder-${BYTESTRING_BUILDER_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/type-equality-${TYPE_EQUALITY_V}.tar.gz
	cp ${FULLDISTDIR}/type-equality-${TYPE_EQUALITY_V}-rev${TYPE_EQUALITY_REV}.cabal ${WRKDIR}/type-equality-${TYPE_EQUALITY_V}/type-equality.cabal
	cp ${FULLDISTDIR}/aeson-${AESON_V}-rev${AESON_REV}.cabal ${WRKDIR}/aeson-${AESON_V}/aeson.cabal
	cp ${FULLDISTDIR}/unliftio-core-${UNLIFTIO_CORE_V}-rev${UNLIFTIO_CORE_REV}.cabal ${WRKDIR}/unliftio-core-${UNLIFTIO_CORE_V}/unliftio-core.cabal
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/prettyprinter-version-compatibility-macros.patch
	cp ${FULLDISTDIR}/vector-stream-${VECTOR_STREAM_V}-rev${VECTOR_STREAM_REV}.cabal ${WRKDIR}/vector-stream-${VECTOR_STREAM_V}/vector-stream.cabal
	cp ${FULLDISTDIR}/attoparsec-${ATTOPARSEC_V}-rev${ATTOPARSEC_REV}.cabal ${WRKDIR}/attoparsec-${ATTOPARSEC_V}/attoparsec.cabal
	cp ${FULLDISTDIR}/bsb-http-chunked-${BSB_HTTP_CHUNKED_V}.cabal ${WRKDIR}/bsb-http-chunked-${BSB_HTTP_CHUNKED_V}/bsb-http-chunked.cabal
	cp ${FULLDISTDIR}/blaze-markup-${BLAZE_MARKUP_V}-rev${BLAZE_MARKUP_REV}.cabal ${WRKDIR}/blaze-markup-${BLAZE_MARKUP_V}/blaze-markup.cabal
	cp ${FULLDISTDIR}/cborg-${CBORG_V}-rev${CBORG_REV}.cabal ${WRKDIR}/cborg-${CBORG_V}/cborg.cabal
	cp ${FULLDISTDIR}/dlist-${DLIST_V}-rev${DLIST_REV}.cabal ${WRKDIR}/dlist-${DLIST_V}/dlist.cabal
	cp ${FULLDISTDIR}/hsc2hs-${HSC2HS_V}-rev${HSC2HS_REV}.cabal ${WRKDIR}/hsc2hs-${HSC2HS_V}/hsc2hs.cabal
	cp ${FULLDISTDIR}/Only-${ONLY_V}-rev${ONLY_REV}.cabal ${WRKDIR}/Only-${ONLY_V}/Only.cabal
	cp ${FULLDISTDIR}/generically-${GENERICALLY_V}-rev${GENERICALLY_REV}.cabal ${WRKDIR}/generically-${GENERICALLY_V}/generically.cabal
	cp ${FULLDISTDIR}/ghc-bignum-orphans-${GHC_BIGNUM_ORPHANS_V}-rev${GHC_BIGNUM_ORPHANS_REV}.cabal ${WRKDIR}/ghc-bignum-orphans-${GHC_BIGNUM_ORPHANS_V}/ghc-bignum-orphans.cabal
	cp ${FULLDISTDIR}/safe-exceptions-${SAFE_EXCEPTIONS_V}-rev${SAFE_EXCEPTIONS_REV}.cabal ${WRKDIR}/safe-exceptions-${SAFE_EXCEPTIONS_V}/safe-exceptions.cabal
	cp ${FULLDISTDIR}/serialise-${SERIALISE_V}-rev${SERIALISE_REV}.cabal ${WRKDIR}/serialise-${SERIALISE_V}/serialise.cabal
	cp ${FULLDISTDIR}/network-uri-${NETWORK_URI_V}-rev${NETWORK_URI_REV}.cabal ${WRKDIR}/network-uri-${NETWORK_URI_V}/network-uri.cabal
	cp ${FULLDISTDIR}/old-locale-${OLD_LOCALE_V}-rev${OLD_LOCALE_REV}.cabal ${WRKDIR}/old-locale-${OLD_LOCALE_V}/old-locale.cabal
	cp ${FULLDISTDIR}/ansi-wl-pprint-${ANSI_WL_PPRINT_V}-rev${ANSI_WL_PPRINT_REV}.cabal ${WRKDIR}/ansi-wl-pprint-${ANSI_WL_PPRINT_V}/ansi-wl-pprint.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/time-manager-${TIME_MANAGER_V}.tar.gz
	# constraints 0.13.4 needs its `forall` export trimmed for GHC 9.10.
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-Data_Constraint_Forall_hs
	# tls-session-manager needs the older tls/auto-update API shape used by the port.
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-Network_TLS_SessionManager_hs
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-Network_TLS_SessionTicket_hs
	patch -d ${WRKDIR} -p0 < ${FILESDIR}/patch-tls-session-manager_cabal

do-build:
	# Build the package from the current directory; explicit exe selectors
	# trigger Cabal's target-matching bug when a source file matches the name.
	cd ${WRKSRC} && env HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
		CABAL_DIR=${WRKDIR}/.cabal cabal build --allow-newer -j \
		--project-file=${PROJECT_FILE}

do-test:
	# Run the upstream test suite for the current package without explicit
	# component selectors for the same Cabal matching reason.
	cd ${WRKSRC} && env HOME=${WRKDIR} XDG_CACHE_HOME=${WRKDIR}/.cache \
		CABAL_DIR=${WRKDIR}/.cabal cabal test --allow-newer -j \
		--project-file=${PROJECT_FILE}

do-install:
	# Install only the server binaries produced by the build.
	smp=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/smp-server/build/smp-server/smp-server' | head -n 1); \
	xftp_server=$$(find ${WRKSRC}/dist-newstyle/build -path '*/x/xftp-server/build/xftp-server/xftp-server' | head -n 1); \
	install -d ${PREFIX}/bin; \
	install -m 755 "$$smp" ${PREFIX}/bin/smp-server; \
	install -m 755 "$$xftp_server" ${PREFIX}/bin/xftp-server

.include "simplexmq.inc"
.include "simplexmq.distfiles.inc"

.include <bsd.port.mk>
