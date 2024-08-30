COMMENT =	secure, private and untraceable digital currency

VERSION =	0.18.3.4
REVISION =	0
PKGNAME =	monero-${VERSION}
DISTNAME =	monero-source-v${VERSION}
SITES =		https://downloads.getmonero.org/cli/
EXTRACT_SUFX =	.tar.bz2

CATEGORIES =	net
HOMEPAGE =	https://getmonero.org

# BSD
PERMIT_PACKAGE =	Yes
ONLY_FOR_ARCHS =	amd64 arm64 armv7 i386 riscv64

WANTLIB += ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_regex-mt boost_serialization-mt boost_system-mt
WANTLIB += boost_thread-mt c crypto ereadline execinfo hidapi-libusb
WANTLIB += m sodium ssl unbound zmq

COMPILER =	base-clang ports-gcc
MODULES =	devel/cmake
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


USE_GMAKE=	Yes

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/bin/* ${PREFIX}/bin/
	${INSTALL_DATA} ${WRKBUILD}/lib/* ${PREFIX}/lib/
	${INSTALL_DATA_DIR} ${PREFIX}/include/wallet/
	${INSTALL_DATA_DIR} ${PREFIX}/include/wallet/api/
	${INSTALL_DATA} ${WRKSRC}/src/wallet/api/wallet2_api.h ${PREFIX}/include/wallet/api/
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${SYSCONFDIR}/monero
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/lib/monero/
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/log/monero/

.include <bsd.port.mk>