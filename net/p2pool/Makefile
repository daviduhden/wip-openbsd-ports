COMMENT =	peer-to-peer mining pool for Monero

V =		4.18.1
GH_ACCOUNT =	SChernykh
GH_PROJECT =	p2pool
GH_TAGNAME =	v${V}
DISTNAME =	${GH_PROJECT}-${V}

# The release archive omits its git submodules.  Pin each source used by
# enabled CMake features so configuration stays offline.
DIST_TUPLE += github SChernykh RandomX \
		12bd428622c103787449f607b19d459a78aabea8 \
		./external/src/RandomX
DIST_TUPLE += github SChernykh cppzmq \
		88c28b1f91a02a041040595c25e20d0f322e609c \
		./external/src/cppzmq
DIST_TUPLE += github SChernykh rapidjson \
		43a1db7dbab5680b351f723ba3baeb86f7bb0b38 \
		./external/src/rapidjson
DIST_TUPLE += github SChernykh robin-hood-hashing \
		cd9ea864b86fcb742e3a0d1c2eebbdf7b0b6af31 \
		./external/src/robin-hood-hashing
DIST_TUPLE += github SChernykh miniupnp \
		7ecef9367c85130fe06dd0d1ced2d247e56fa60b \
		./external/src/miniupnp
# P2Pool uses BoringSSL APIs for pool-key signatures and Stratum TLS.
DIST_TUPLE += github google boringssl \
		30a26e970e14f9d943e3961de49bee5cc7e032d3 \
		./external/src/grpc/third_party/boringssl-with-bazel

CATEGORIES =	net
ONLY_FOR_ARCHS =	amd64 arm64 riscv64
HOMEPAGE =	https://github.com/SChernykh/p2pool
MAINTAINER =	David Uhden Collado <daviduhden@gmail.com>

# GPLv3+
PERMIT_PACKAGE =	Yes

WANTLIB += ${COMPILER_LIBCXX} c curl m pthread uv zmq

MODULES =	devel/cmake
COMPILER =	base-clang ports-gcc

LIB_DEPENDS =	devel/libuv \
			net/curl \
			net/zeromq

CONFIGURE_ARGS += -DWITH_GRPC=OFF \
			-DWITH_RANDOMX=ON \
			-DWITH_TLS=ON \
			-DWITH_UPNP=ON

# P2Pool accepts settings on the command line and has no OpenBSD rc.d
# integration; installation does not start mining or a service.
do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/p2pool ${PREFIX}/bin/p2pool

.include <bsd.port.mk>
