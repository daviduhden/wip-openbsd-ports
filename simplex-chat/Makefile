# Replace ??? with appropriate values
# Remove extraneous comments before commit
# Use /usr/ports/infrastructure/bin/portcheck

COMMENT =	private by design messaging network

VERSION =	6.0.0.8
PKGNAME =	simplex-chat-${VERSION}

CATEGORIES =	net
HOMEPAGE =	https://simplex.chat

# AGPLv3+
PERMIT_PACKAGE =	Yes

WANTLIB =

MODULES =	devel/cabal

BUILD_DEPENDS =	\
	lang/ghc \
	devel/cabal-install

MODCABAL_STEM =	simplex-chat
MODCABAL_VERSION =	${VERSION}
MODCABAL_MANIFEST =	\
	base 4.14.3.0 0 \
	directory 1.3.6.0 0 \
	aeson 2.2.0.0 0 \
	ansi-terminal 0.11.0 0 \
	async 2.2.4 0 \
	attoparsec 0.14.4 0 \
	containers 0.6.5.1 0 \
	crypton 0.34.0 0 \
	data-default 0.7.1 0 \
	direct-sqlcipher 2.3.0 0 \
	email-validate 2.3.2 0 \
	exceptions 0.10.4 0 \
	filepath 1.4.2.1 0 \
	http-types 0.12.3 0 \
	http2 4.2.2 0 \
	memory 0.18.0 0 \
	mtl 2.3.1 0 \
	network 3.1.2.7 0 \
	optparse-applicative 0.16.1.0 0 \
	random 1.2.0 0 \
	record-hasfield 1.0.0 0 \
	simple-logger 0.1.1 0 \
	simplexmq 5.0.0 0 \
	socks 0.6.1 0 \
	sqlcipher-simple 0.4.0 0 \
	stm 2.5.0.1 0 \
	terminal 0.2.0.1 0 \
	time 1.9.3 0 \
	tls 1.7.0 0 \
	unliftio 0.2.23 0 \
	unliftio-core 0.2.0 0 \
	zip 2.0.1 0

pre-install:
	cp ${WRKSRC}/scripts/cabal.project.local.linux ${WRKSRC}/cabal.project.local

post-install:
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/simplex-chat/
	${INSTALL_DATA} ${WRKSRC}/LICENSE ${PREFIX}/share/doc/simplex-chat/

.include <bsd.port.mk>
