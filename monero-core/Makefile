COMMENT=	decentralized cryptocurrency with untraceable transactions

VERSION=	0.18.3.3
PKGNAME=	monero-${VERSION}
DISTNAME=	monero-source-v${VERSION}
MASTER_SITES=	https://downloads.getmonero.org/cli/
EXTRACT_SUFX=	.tar.bz2

CATEGORIES=	net

# BSD
PERMIT_PACKAGE=	Yes

WANTLIB=	c

MODULES=	devel/cmake
CONFIGURE_ARGS += -DBUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Release

BUILD_DEPENDS=	devel/boost devel/gtest lang/python/3.10 net/libunbound net/zeromq

# optional
BUILD_DEPENDS+=	comms/libhidapi converters/libiconv databases/lmdb devel/doxygen math/graphviz net/miniupnp/miniupnpc

do-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc
	cp -r ${WRKSRC}/docs ${PREFIX}/share/doc/${PKGNAME}

.include <bsd.port.mk>
