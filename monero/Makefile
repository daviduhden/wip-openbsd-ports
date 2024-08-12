COMMENT=secure, private and untraceable cryptocurrency

VERSION=0.18.3.3
PKGNAME=monero-${VERSION}
DISTNAME=monero-source-v${VERSION}
SITES=https://downloads.getmonero.org/cli/
EXTRACT_SUFX=.tar.bz2

CATEGORIES=net
HOMEPAGE=https://getmonero.org

# BSD
PERMIT_PACKAGE=Yes

WANTLIB=c

COMPILER=base-clang ports-gcc
MODULES=devel/cmake

BUILD_DEPENDS=devel/boost net/zeromq net/libunbound converters/libiconv
RUN_DEPENDS=devel/boost net/zeromq net/libunbound converters/libiconv

USE_GMAKE=Yes

do-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc
	cp -r ${WRKSRC}/docs ${PREFIX}/share/doc/${PKGNAME}
	${INSTALL_PROGRAM} ${WRKSRC}/build/release/monerod ${PREFIX}/bin/
	${INSTALL_PROGRAM} ${WRKSRC}/build/release/monero-wallet-cli ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${PREFIX}/etc/monero
	${INSTALL_DATA} ${WRKSRC}/utils/conf/monerod.conf ${PREFIX}/etc/monero/

.include <bsd.port.mk>