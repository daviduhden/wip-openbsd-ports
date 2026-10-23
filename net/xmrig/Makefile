COMMENT =		high performance Monero CPU miner

V =			6.26.0
GH_ACCOUNT =		xmrig
GH_PROJECT =		xmrig
GH_TAGNAME =		v${V}
DISTNAME =		xmrig-${V}
CATEGORIES =		net
HOMEPAGE =		https://github.com/xmrig/xmrig
MAINTAINER =		David Uhden Collado <daviduhden@gmail.com>

# GPLv3+
PERMIT_PACKAGE =	Yes

ONLY_FOR_ARCHS =	amd64 arm64 armv7 riscv64

WANTLIB +=		${COMPILER_LIBCXX} c crypto m pthread ssl uv

MODULES =		devel/cmake
COMPILER =		base-clang ports-gcc
BUILD_DEPENDS =		devel/ninja
LIB_DEPENDS =		devel/libuv

CONFIGURE_ARGS =	-GNinja \
			-DWITH_CUDA=OFF \
			-DWITH_OPENCL=OFF \
			-DWITH_HWLOC=OFF \
			-DWITH_MSR=OFF \
			-DWITH_HTTP=ON \
			-DWITH_TLS=ON \
			-DWITH_SECURE_JIT=ON

# XMRig uses just-in-time code generation. OpenBSD requires generated
# code to transition from writable to executable mappings.

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/xmrig ${PREFIX}/bin/xmrig
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/xmrig
	${INSTALL_DATA} ${WRKSRC}/src/config.json \
		${PREFIX}/share/examples/xmrig/config.json

.include <bsd.port.mk>
