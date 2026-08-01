COMMENT = Monero Light Wallet Server

VERSION = 0.18.5.1
PKGNAME = monero-lws-${VERSION}
MONERO_SERIES = ${VERSION:C/\.[0-9]+\.[0-9]+$//}
LWS_VERSION = release-v1.0_${MONERO_SERIES}

DISTFILES = ${LWS_VERSION}.tar.gz \
		${MONERO_DIST}
MONERO_DIST = monero-source-v${VERSION}.tar.bz2
SITES = https://github.com/vtnerd/monero-lws/archive/refs/heads/
SITES.${MONERO_DIST} = https://downloads.getmonero.org/cli/

WRKDIST = ${WRKDIR}/monero-lws-${LWS_VERSION}
MONERO_WRKSRC = ${WRKDIR}/monero-source-v${VERSION}
MONERO_WRKBUILD = ${WRKDIR}/monero-build
LWS_WRKBUILD = ${WRKDIR}/lws-build

CATEGORIES = net
HOMEPAGE = https://github.com/vtnerd/monero-lws
MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# BSD 3-Clause "New" or "Revised" License
PERMIT_PACKAGE = Yes
ONLY_FOR_ARCHS = amd64 i386 arm64 armv7 riscv64

WANTLIB += ${COMPILER_LIBCXX} boost_chrono-mt boost_date_time-mt
WANTLIB += boost_filesystem-mt boost_locale-mt boost_program_options-mt
WANTLIB += boost_serialization-mt boost_thread-mt c crypto curses
WANTLIB += ereadline execinfo hidapi-libusb iconv m protobuf
WANTLIB += sodium ssl unbound zmq

COMPILER = base-clang ports-gcc
MODULES = devel/cmake
BUILD_DEPENDS = devel/ninja

RUN_DEPENDS = net/monero=${VERSION}

LIB_DEPENDS = devel/boost \
		devel/protobuf \
		devel/readline \
		net/zeromq \
		net/libunbound \
		converters/libiconv \
		comms/libhidapi

# Apply monero patches to the vendored monero source.
MONERO_PATCHES += patch-cmake_FindLibunwind_cmake
MONERO_PATCHES += patch-cmake_FindReadline_cmake
MONERO_PATCHES += patch-CMakeLists_txt
MONERO_PATCHES += patch-contrib_depends_toolchain_cmake_in
MONERO_PATCHES += patch-src_device_device_io_hid_cpp

post-patch:
.for _p in ${MONERO_PATCHES}
	patch -d ${MONERO_WRKSRC} -p0 < ${FILESDIR}/${_p}
.endfor

do-build:
	cd ${MONERO_WRKSRC} && cmake -S ${MONERO_WRKSRC} -B ${MONERO_WRKBUILD} \
	    -GNinja \
	    -DCMAKE_BUILD_TYPE=Release \
	    -Wno-dev \
	    -DDEPENDS=ON \
	    -DMANUAL_SUBMODULES=ON \
	    -DBUILD_DOCUMENTATION=OFF
	cmake --build ${MONERO_WRKBUILD}
	cd ${WRKSRC} && cmake -S ${WRKSRC} -B ${LWS_WRKBUILD} \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DMONERO_SOURCE_DIR=${MONERO_WRKSRC} \
	    -DMONERO_BUILD_DIR=${MONERO_WRKBUILD}
	cmake --build ${LWS_WRKBUILD}

do-install:
	${INSTALL_PROGRAM} ${LWS_WRKBUILD}/src/monero-lws-daemon ${PREFIX}/bin/
	${INSTALL_PROGRAM} ${LWS_WRKBUILD}/src/monero-lws-admin ${PREFIX}/bin/
	${INSTALL_PROGRAM} ${LWS_WRKBUILD}/src/monero-lws-client ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/monero-lws
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/lib/monero-lws
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/log/monero-lws

.include <bsd.port.mk>
