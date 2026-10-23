COMMENT =	FIDO2 command-line tools

V =		1.17.0
DISTNAME =	libfido2-${V}
PKGNAME =	fido2-tools-${V}
SITES =	https://developers.yubico.com/libfido2/Releases/

CATEGORIES =	security
HOMEPAGE =	https://github.com/Yubico/libfido2

# BSD 2-Clause
PERMIT_PACKAGE =	Yes

WANTLIB +=	cbor crypto fido2 z c

MODULES =	devel/cmake
COMPILER =	base-clang

CONFIGURE_ARGS +=	-DBUILD_TESTS=OFF \
			-DBUILD_EXAMPLES=OFF \
			-DBUILD_MANPAGES=ON \
			-DBUILD_SHARED_LIBS=OFF \
			-DBUILD_STATIC_LIBS=OFF \
			-DBUILD_TOOLS=ON \
			-DUSE_SYSTEM_FIDO2=ON \
			-DUSE_HIDAPI=OFF \
			-DUSE_PCSC=OFF \
			-DNFC_LINUX=OFF \
			-DUSE_WINHELLO=OFF

.include <bsd.port.mk>
