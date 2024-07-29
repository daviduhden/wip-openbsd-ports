COMMENT=client for the I2P anonymous network

GH_ACCOUNT=PurpleI2P
GH_PROJECT=i2pd
GH_TAGNAME=2.53.0

CATEGORIES=net
HOMEPAGE=https://i2pd.website

# BSD
PERMIT_PACKAGE=Yes

WANTLIB+=${COMPILER_LIBCXX} boost_atomic-mt boost_date_time-mt
WANTLIB+=boost_filesystem-mt boost_program_options-mt boost_system-mt
WANTLIB+=c m z

COMPILER=base-clang ports-gcc
MODULES=devel/cmake
LIB_DEPENDS=devel/boost

# LibreSSL support has been removed in version 2.53.0
BUILD_DEPENDS+=security/openssl/3.2
# Linked statically to avoid conflicts with shared libcrypto from the base OS
CONFIGURE_ARGS+=-DWITH_STATIC=ON
MAKE_CCARGS+=-I${LOCALBASE}/include/eopenssl32
MAKE_AUXLIBS+=${LOCALBASE}/lib/eopenssl32/libssl.a \
		${LOCALBASE}/lib/eopenssl32/libcrypto.a
WANTLIB+=${LOCALBASE}/lib/eopenssl32/libssl.a \
		${LOCALBASE}/lib/eopenssl32/libcrypto.a

USE_GMAKE=Yes

FLAVORS+=upnp
FLAVOR?=

.if ${FLAVOR:Mupnp}
LIB_DEPENDS+=net/miniupnp/miniupnpc
CONFIGURE_ARGS+=-DWITH_UPNP=ON
.endif

WRKSRC=${WRKDIST}/build

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/include/i2pd
	${INSTALL_DATA} ${WRKDIST}/libi2pd{,_client}/*.h \
		${PREFIX}/include/i2pd
.for dir in family reseed
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/i2pd/certificates/${dir}
	${INSTALL_DATA} ${WRKDIST}/contrib/certificates/${dir}/* \
		${PREFIX}/share/examples/i2pd/certificates/${dir}
.endfor
	${INSTALL_DATA} ${WRKDIST}/contrib/i2pd.conf \
		${PREFIX}/share/examples/i2pd/i2pd.conf
	${INSTALL_DATA} ${WRKDIST}/contrib/tunnels.conf \
		${PREFIX}/share/examples/i2pd/tunnels.conf

do-test:
	cd ${WRKDIST}/tests && ${MAKE_PROGRAM} CXX="${CXX}" \
		INCFLAGS="-L${LOCALBASE}/lib -I${LOCALBASE}/include ${CFLAGS}"

.include <bsd.port.mk>
