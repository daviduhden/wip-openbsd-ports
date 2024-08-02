COMMENT=secure, private and untraceable cryptocurrency

GH_ACCOUNT=monero-project
GH_PROJECT=monero
GH_TAGNAME=v0.18.3.3

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

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc
	cp -r ${WRKSRC}/docs ${PREFIX}/share/doc/${PKGNAME}
	${INSTALL_PROGRAM} ${WRKSRC}/bin/monerod ${PREFIX}/bin/
	${INSTALL_PROGRAM} ${WRKSRC}/bin/monero-wallet-cli ${PREFIX}/bin/
	${INSTALL_DATA_DIR} ${PREFIX}/etc/monero
	${INSTALL_DATA} ${WRKSRC}/monero.conf ${PREFIX}/etc/monero/

.include <bsd.port.mk>