COMMENT =		key and address utilities for the I2P network

GH_ACCOUNT =		PurpleI2P
GH_PROJECT =		i2pd-tools
GH_TAGNAME =		2.58.0
CATEGORIES =		net

# BSD-3-Clause (tools and the pinned i2pd sources)
PERMIT_PACKAGE =	Yes

WANTLIB +=		${COMPILER_LIBCXX} boost_program_options-mt c crypto
WANTLIB +=		m pthread ssl z

COMPILER =		base-clang ports-gcc
LIB_DEPENDS =		devel/boost
USE_GMAKE =		Yes

# Exact gitlink in tools tag 2.58.0, not the separately installed i2pd port.
I2PD_COMMIT =		80080fd8f5df5c8c07df044458eedbf8fbbbe86c
SITES.i2pd =		https://github.com/PurpleI2P/i2pd/archive/
DISTFILES.i2pd =		i2pd-${I2PD_COMMIT:C/(........).*/\1/}{${I2PD_COMMIT}}.tar.gz

# Boost.System is header-only. FS.h selects std::filesystem with C++17.
MAKE_FLAGS =		CXX="${CXX}" \
			CXXFLAGS="${CXXFLAGS} -std=c++17 -I${LOCALBASE}/include" \
			LDFLAGS="${LDFLAGS} -L${LOCALBASE}/lib" \
			LDLIBS="i2pd/libi2pd.a -lboost_program_options-mt -lssl -lcrypto -lz -lpthread" \
			USE_GIT_VERSION=no USE_UPNP=no

TOOLS =			autoconf b33address famtool i2pbase64 keygen keyinfo \
			offlinekeys regaddr regaddr_3ld regaddralias routerinfo \
			vain verifyhost x25519

# The tools release has no test target; i2pd's separate daemon tests are not
# a test suite for these command-line tools.
NO_TEST =		Yes

post-extract:
	rmdir ${WRKSRC}/i2pd
	mv ${WRKDIR}/i2pd-${I2PD_COMMIT} ${WRKSRC}/i2pd

do-install:
	${INSTALL_PROGRAM_DIR} ${PREFIX}/libexec/i2pd-tools
	${SUBST_CMD} -c -m 555 ${FILESDIR}/i2pd-tool \
		${WRKDIR}/i2pd-tool
.for tool in ${TOOLS}
	${INSTALL_PROGRAM} ${WRKSRC}/${tool} ${PREFIX}/libexec/i2pd-tools/
	${INSTALL_SCRIPT} ${WRKDIR}/i2pd-tool ${PREFIX}/bin/i2pd-${tool}
.endfor
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/i2pd-tools
	${INSTALL_DATA} ${WRKSRC}/LICENSE \
		${PREFIX}/share/doc/i2pd-tools/

.include <bsd.port.mk>
