COMMENT = Private and encrypted chat platform (terminal client)
# Keep the client release version separate from the server dependency pin so
# the terminal client can track upstream independently.
V = 6.5.4.0
V_BASE = ${V:C/\.0$//}
SIMPLEXMQ_V = 6.5.3.0
DISTNAME = simplex-chat-${V}
WRKDIST = ${WRKDIR}/simplex-chat-${V_BASE}
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
DISTFILES += simplexmq-${SIMPLEXMQ_V}${EXTRACT_SUFX}{simplexmq/archive/refs/heads/stable.tar.gz}
EXTRACT_ONLY = simplex-chat-${V}${EXTRACT_SUFX}
EXTRACT_ONLY += simplexmq-${SIMPLEXMQ_V}${EXTRACT_SUFX}

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
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-transport.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-http2.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-parsers.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-rc-types.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-keepalive.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-http2-server.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-http2-client.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-client.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/simplexmq-stable-cabal.patch
	# entropy's Setup.hs is the default Main/defaultMain wrapper, so a
	# simple build avoids an unnecessary Cabal/parsec setup dependency.
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/entropy-cabal.patch
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/Only-${ONLY_V}.tar.gz
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/Only-cabal.patch
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/unicode-transforms-cabal.patch
	tar -C ${WRKSRC} -xzf ${FULLDISTDIR}/splitmix-${SPLITMIX_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/asn1-encoding-${ASN1_ENCODING_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/asn1-parse-${ASN1_PARSE_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/asn1-types-${ASN1_TYPES_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/crypto-token-${CRYPTO_TOKEN_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/crypton-${CRYPTON_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/crypton-x509-${CRYPTON_X509_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/crypton-x509-store-${CRYPTON_X509_STORE_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/crypton-x509-validation-${CRYPTON_X509_VALIDATION_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/cryptostore-${CRYPTOSTORE_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/pem-${PEM_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/constraints-${CONSTRAINTS_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/boring-${BORING_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/base16-bytestring-${BASE16_BYTESTRING_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/data-default-instances-containers-${DATA_DEFAULT_INSTANCES_CONTAINERS_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/data-default-instances-dlist-${DATA_DEFAULT_INSTANCES_DLIST_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/data-default-instances-old-locale-${DATA_DEFAULT_INSTANCES_OLD_LOCALE_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/bitvec-${BITVEC_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/blaze-html-${BLAZE_HTML_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/blaze-markup-${BLAZE_MARKUP_V}.tar.gz
	cp ${FULLDISTDIR}/blaze-markup-${BLAZE_MARKUP_V}-rev${BLAZE_MARKUP_REV}.cabal ${WRKDIR}/blaze-markup-${BLAZE_MARKUP_V}/blaze-markup.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/blaze-textual-${BLAZE_TEXTUAL_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/bsb-http-chunked-${BSB_HTTP_CHUNKED_V}.tar.gz
	cp ${FULLDISTDIR}/bsb-http-chunked-${BSB_HTTP_CHUNKED_V}-rev${BSB_HTTP_CHUNKED_REV}.cabal ${WRKDIR}/bsb-http-chunked-${BSB_HTTP_CHUNKED_V}/bsb-http-chunked.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/call-stack-${CALL_STACK_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/cborg-${CBORG_V}.tar.gz
	cp ${FULLDISTDIR}/cborg-${CBORG_V}-rev${CBORG_REV}.cabal ${WRKDIR}/cborg-${CBORG_V}/cborg.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/cereal-${CEREAL_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/clock-${CLOCK_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/composition-${COMPOSITION_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/generic-random-${GENERIC_RANDOM_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/half-${HALF_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/hashmap-${HASHMAP_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/hsc2hs-${HSC2HS_V}.tar.gz
	cp ${FULLDISTDIR}/hsc2hs-${HSC2HS_V}-rev${HSC2HS_REV}.cabal ${WRKDIR}/hsc2hs-${HSC2HS_V}/hsc2hs.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/http-date-${HTTP_DATE_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/ini-${INI_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/iso8601-time-${ISO8601_TIME_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/network-udp-${NETWORK_UDP_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/old-locale-${OLD_LOCALE_V}.tar.gz
	cp ${FULLDISTDIR}/old-locale-${OLD_LOCALE_V}-rev${OLD_LOCALE_REV}.cabal ${WRKDIR}/old-locale-${OLD_LOCALE_V}/old-locale.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/old-time-${OLD_TIME_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/recv-${RECV_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/serialise-${SERIALISE_V}.tar.gz
	cp ${FULLDISTDIR}/serialise-${SERIALISE_V}-rev${SERIALISE_REV}.cabal ${WRKDIR}/serialise-${SERIALISE_V}/serialise.cabal
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/simple-sendfile-${SIMPLE_SENDFILE_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/temporary-${TEMPORARY_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/vault-${VAULT_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/wai-app-static-${WAI_APP_STATIC_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/wai-extra-${WAI_EXTRA_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/wai-logger-${WAI_LOGGER_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/word8-${WORD8_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/zlib-${ZLIB_V}.tar.gz
	tar -C ${WRKDIR} -xzf ${FULLDISTDIR}/prettyprinter-${PRETTYPRINTER_V}.tar.gz
	patch -d ${WRKDIR} -p1 < ${FILESDIR}/prettyprinter-version-compatibility-macros.patch
	cp ${FULLDISTDIR}/safe-exceptions-${SAFE_EXCEPTIONS_V}-rev${SAFE_EXCEPTIONS_REV}.cabal ${WRKDIR}/safe-exceptions-${SAFE_EXCEPTIONS_V}/safe-exceptions.cabal
	cp ${FULLDISTDIR}/attoparsec-${ATTOPARSEC_V}-rev${ATTOPARSEC_REV}.cabal ${WRKDIR}/attoparsec-${ATTOPARSEC_V}/attoparsec.cabal
	cp ${FULLDISTDIR}/cryptohash-md5-${CRYPTOHASH_MD5_V}-rev6.cabal ${WRKDIR}/cryptohash-md5-${CRYPTOHASH_MD5_V}/cryptohash-md5.cabal
	cp ${FULLDISTDIR}/cryptohash-sha1-${CRYPTOHASH_SHA1_V}-rev6.cabal ${WRKDIR}/cryptohash-sha1-${CRYPTOHASH_SHA1_V}/cryptohash-sha1.cabal
	cp ${FULLDISTDIR}/aeson-${AESON_V}-rev${AESON_REV}.cabal ${WRKDIR}/aeson-${AESON_V}/aeson.cabal
	cp ${FULLDISTDIR}/dlist-${DLIST_V}-rev${DLIST_REV}.cabal ${WRKDIR}/dlist-${DLIST_V}/dlist.cabal
	cp ${FULLDISTDIR}/unliftio-core-${UNLIFTIO_CORE_V}-rev${UNLIFTIO_CORE_REV}.cabal ${WRKDIR}/unliftio-core-${UNLIFTIO_CORE_V}/unliftio-core.cabal
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
