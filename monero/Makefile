COMMENT =	secure, private and untraceable digital currency

VERSION =	0.18.5.0
REVISION =	0
PKGNAME =	monero-${VERSION}
DISTNAME =	monero-source-v${VERSION}
SITES =		https://downloads.getmonero.org/cli/
EXTRACT_SUFX =	.tar.bz2
LWS_VERSION =	release-v1.0_0.18
LWS_DISTFILE =	${LWS_VERSION}.tar.gz
LWS_WRKSRC =	${WRKDIR}/monero-lws-${LWS_VERSION}
LWS_WRKBUILD =	${LWS_WRKSRC}/build

CATEGORIES =	net
HOMEPAGE =	https://getmonero.org
MAINTAINER =	David Uhden Collado <daviduhden@gmail.com>

# BSD
PERMIT_PACKAGE =	Yes
ONLY_FOR_ARCHS =	amd64 i386 arm64 armv7 riscv64

WANTLIB += ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_serialization-mt boost_thread-mt c crypto curses
WANTLIB += ereadline execinfo hidapi-libusb m sodium ssl unbound zmq

COMPILER =	base-clang ports-gcc
MODULES =	devel/cmake
BUILD_DEPENDS =	devel/ninja

FLAVORS =	lws
PLIST_VARS +=	lws
.if ${FLAVOR:Mlws}
DISTFILES +=	${LWS_DISTFILE}
SITES.${LWS_DISTFILE} =	https://github.com/vtnerd/monero-lws/archive/refs/heads/
PLIST_lws =
.else
PLIST_lws =	@comment
.endif

CONFIGURE_ARGS += -Wno-dev \
		  -DDEPENDS=ON \
		  -DMANUAL_SUBMODULES=ON \
		  -DBUILD_DOCUMENTATION=OFF

LIB_DEPENDS =	devel/boost \
		devel/protobuf \
		devel/readline \
		net/zeromq \
		net/libunbound \
		converters/libiconv \
		comms/libhidapi

TEST_DEPENDS =	lang/python/3

USE_GMAKE=	Yes

post-build:
.if ${FLAVOR:Mlws}
	cd ${LWS_WRKSRC} && cmake -S ${LWS_WRKSRC} -B ${LWS_WRKBUILD} \
		-DCMAKE_BUILD_TYPE=Release \
		-DMONERO_SOURCE_DIR=${WRKSRC} \
		-DMONERO_BUILD_DIR=${WRKBUILD}
	cmake --build ${LWS_WRKBUILD}
.endif

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
.if ${FLAVOR:Mlws}
	${INSTALL_PROGRAM} ${LWS_WRKBUILD}/src/monero-lws-daemon ${PREFIX}/bin/
	${INSTALL_PROGRAM} ${LWS_WRKBUILD}/src/monero-lws-admin ${PREFIX}/bin/
	${INSTALL_PROGRAM} ${LWS_WRKBUILD}/src/monero-lws-client ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/monero-lws
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/lib/monero-lws
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/log/monero-lws
.endif

.include <bsd.port.mk>
