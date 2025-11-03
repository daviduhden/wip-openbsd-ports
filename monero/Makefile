COMMENT =	secure, private and untraceable digital currency

VERSION =	0.18.4.3
PKGNAME =	monero-${VERSION}
DISTNAME =	monero-source-v${VERSION}
SITES =		https://downloads.getmonero.org/cli/
EXTRACT_SUFX =	.tar.bz2

CATEGORIES =	net
HOMEPAGE =	https://getmonero.org

# BSD
PERMIT_PACKAGE =	Yes
ONLY_FOR_ARCHS =	amd64 i386 arm64 armv7 riscv64

WANTLIB += ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_serialization-mt boost_thread-mt c crypto ereadline
WANTLIB += execinfo hidapi-libusb m sodium ssl unbound zmq

COMPILER =	base-clang ports-gcc
MODULES =	devel/cmake
BUILD_DEPENDS =	devel/ninja

CONFIGURE_ARGS += -Wno-dev \
		-DMANUAL_SUBMODULES=ON \
		-DBUILD_DOCUMENTATION=OFF

LIB_DEPENDS =	devel/boost \
		devel/protobuf \
		devel/readline \
		net/zeromq \
		net/libunbound \
		converters/libiconv \
		comms/libhidapi \
		net/miniupnp/miniupnpc

TEST_DEPENDS =	lang/python/3

USE_GMAKE=	Yes

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/bin/* ${PREFIX}/bin/
	${INSTALL_DATA} ${WRKBUILD}/lib/* ${PREFIX}/lib/
	${INSTALL_DATA_DIR} ${PREFIX}/include/wallet
	${INSTALL_DATA_DIR} ${PREFIX}/include/wallet/api
	${INSTALL_DATA} ${WRKSRC}/src/wallet/api/wallet2_api.h ${PREFIX}/include/wallet/api/
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${SYSCONFDIR}/monero/
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/lib/monero
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/log/monero

.include <bsd.port.mk>