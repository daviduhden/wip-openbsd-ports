ONLY_FOR_ARCHS =	amd64 aarch64 i386 powerpc64 riscv64
DPB_PROPERTIES =	parallel

USE_WXNEEDED =		Yes

COMMENT = JavaScript runtime built on Chrome's V8 JavaScript engine

NODE_VERSION =		v24.22.2
DISTFILES =		${DISTNAME}-headers.tar.gz \
			${DISTNAME}.tar.xz
DIST_TUPLE =		codeberg qbit node-pledge 1.1.4 \
			deps/npm/node_modules/node-pledge
DISTNAME =		node-${NODE_VERSION}
PKGNAME =		${DISTNAME:S/v//g}
EPOCH =			0
REVISION =		1

CATEGORIES =		lang devel

HOMEPAGE =		https://nodejs.org/
MAINTAINER =		Volker Schlecht <volker@openbsd.org>

# MIT
PERMIT_PACKAGE =	Yes

SITES =			${HOMEPAGE}dist/${NODE_VERSION}/

MODULES =		lang/python

WANTLIB += ${COMPILER_LIBCXX} c cares crypto execinfo icudata icui18n
WANTLIB += icuuc m nghttp2 nghttp3 simdutf ssl uv z

COMPILER =		base-clang ports-gcc

USE_GMAKE =		Yes

BUILD_DEPENDS =		sysutils/flock

RUN_DEPENDS =		devel/gmake \
			sysutils/flock

CONFIGURE_STYLE =	simple
CONFIGURE_SCRIPT =	configure

CONFIGURE_ARGS =	--prefix=${PREFIX} \
			--with-intl=system-icu \
			--shared-cares \
			--shared-libuv \
			--shared-nghttp2 \
			--shared-nghttp3 \
			--shared-simdutf \
			--shared-zlib \
			--shared-openssl

CFLAGS +=		-idirafter ${LOCALBASE}/include

SUBST_VARS +=		DISTNAME
SUBST_VARS +=		WRKDIST
SUBST_VARS +=		NODE_VERSION

LIB_DEPENDS +=		\
			devel/libuv>=1.51.0p0 \
			net/libcares \
			textproc/icu4c \
			textproc/simdutf \
			www/nghttp2 \
			www/nghttp3

DEBUG_PACKAGES =	${BUILD_PACKAGES}

# Run default tests, without linters or building the docs.
TEST_TARGET =		test-only
TEST_ENV =		${MAKE_ENV} HOME=${WRKSRC} CI=true

# Skip test-snapshot-reproducible.
# It fails and is too verbose (pollutes log with binary diff).
TEST_ENV+=		CI_SKIP_TESTS=test-snapshot-reproducible

pre-configure:
	${SUBST_CMD} ${WRKDIST}/common.gypi \
		${WRKDIST}/deps/npm/node_modules/node-gyp/lib/install.js \
		${WRKDIST}/tools/test.py

post-install:
	${MODPY_COMPILEALL} \
		${PREFIX}/lib/node_modules/npm/node_modules/node-gyp
	${INSTALL_DATA_DIR} ${PREFIX}/share/node
	${INSTALL_DATA} ${FULLDISTDIR}/${DISTNAME}-headers.tar.gz \
		${PREFIX}/share/node/${DISTNAME}-headers.tar.gz
	cd ${PREFIX}/lib/node_modules/npm/node_modules && for x in *; do \
		mv $$x ../..; \
		ln -s ../../$$x $$x; \
	done

# Includes a lot of networking tests that will fail when running as _pbuild
do-test:
	cd ${WRKSRC} && \
	ulimit -n $$(ulimit -Hn) && \
	ulimit -d $$(ulimit -Hd) && \
	${SETENV} ${TEST_ENV} ${MAKE_PROGRAM} --ignore-errors ${TEST_TARGET}

.include <bsd.port.mk>
