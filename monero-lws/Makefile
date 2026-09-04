COMMENT = Monero Light Wallet Server

GH_ACCOUNT = vtnerd
GH_PROJECT = monero-lws
GH_COMMIT = ace5f7dcf705d535c196ff83517911c80ca3f655

VERSION = 0.18.5.1
MONERO_SERIES = ${VERSION:C/\.[0-9]+\.[0-9]+$//}
LWS_VERSION = release-v1.0_${MONERO_SERIES}
DISTNAME = ${GH_PROJECT}-${LWS_VERSION}
PKGNAME = monero-lws-${VERSION}
REVISION = 0

DISTFILES = ${GH_DISTFILE} \
		${MONERO_DIST}
MONERO_DIST = monero-source-v${VERSION}.tar.bz2
SITES = ${SITES_GITHUB}
SITES.${MONERO_DIST} = https://downloads.getmonero.org/cli/

WRKDIST = ${WRKDIR}/${GH_PROJECT}-${GH_COMMIT}
MONERO_WRKSRC = ${WRKDIR}/monero-source-v${VERSION}
MONERO_WRKBUILD = ${WRKDIR}/monero-build
LWS_WRKBUILD = ${WRKDIR}/lws-build

CATEGORIES = net
HOMEPAGE = https://github.com/vtnerd/monero-lws
MAINTAINER = David Uhden Collado <daviduhden@gmail.com>

# BSD 3-Clause "New" or "Revised" License
PERMIT_PACKAGE = Yes
ONLY_FOR_ARCHS = amd64 i386 arm64 armv7 riscv64

WANTLIB += ${COMPILER_LIBCXX} boost_chrono-mt boost_context-mt
WANTLIB += boost_coroutine-mt boost_filesystem-mt boost_program_options-mt
WANTLIB += boost_regex-mt boost_serialization-mt boost_thread-mt
WANTLIB += c crypto hidapi-libusb m sodium ssl unbound usb-1.0 zmq

COMPILER = base-clang
MODULES = devel/cmake
BUILD_DEPENDS = devel/ninja \
		devel/re2c

RUN_DEPENDS = net/monero=${VERSION}

# Boost.Context and Boost.Coroutine are provided by the -md subpackage.
LIB_DEPENDS = devel/boost,-md \
		devel/libusb1 \
		devel/protobuf \
		devel/readline \
		net/zeromq \
		net/libunbound \
		converters/libiconv \
		comms/libhidapi

# Apply monero patches to the vendored monero source.
MONERO_PATCHES += patch-cmake_FindLibunwind_cmake
MONERO_PATCHES += patch-cmake_FindReadline_cmake
MONERO_PATCHES += patch-cmake_CheckTrezor_cmake
MONERO_PATCHES += patch-CMakeLists_txt
MONERO_PATCHES += patch-contrib_depends_toolchain_cmake_in
MONERO_PATCHES += patch-external_db_drivers_liblmdb_mdb_c
MONERO_PATCHES += patch-src_device_device_io_hid_cpp
MONERO_PATCHES += patch-src_serialization_binary_archive_h

post-patch:
.for _p in ${MONERO_PATCHES}
	patch -d ${MONERO_WRKSRC} -p0 < ${FILESDIR}/${_p}
.endfor

do-configure:
	cd ${MONERO_WRKSRC} && cmake -S ${MONERO_WRKSRC} -B ${MONERO_WRKBUILD} \
	    -GNinja \
	    -DCMAKE_BUILD_TYPE=Release \
	    -Wno-dev \
	    -DDEPENDS=ON \
	    -DMANUAL_SUBMODULES=ON \
	    -DBUILD_DOCUMENTATION=OFF

do-build:
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
