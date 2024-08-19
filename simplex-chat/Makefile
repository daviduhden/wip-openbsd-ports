COMMENT =	private by design messaging network

VERSION =	6.0.0.8
PKGNAME =	simplex-chat-${VERSION}

CATEGORIES =	net
HOMEPAGE =	https://simplex.chat

# AGPLv3 only
PERMIT_PACKAGE =	Yes

WANTLIB =

BUILD_DEPENDS =	\
	lang/ghc \
	devel/cabal-bundler \
	devel/cabal-install \
	devel/git

pre-install:
	cp ${WRKSRC}/scripts/cabal.project.local.linux ${WRKSRC}/cabal.project.local

do-install:
	cd ${WRKSRC} && cabal update
	cd ${WRKSRC} && cabal install

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/simplex-chat/
	${INSTALL_DATA} ${WRKSRC}/LICENSE ${PREFIX}/share/doc/simplex-chat/

.include <bsd.port.mk>
