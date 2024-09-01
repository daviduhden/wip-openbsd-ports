COMMENT =	i2p-only BitTorrent client written in Go

MODGO_MODNAME =	github.com/majestrate/XD
MODGO_VERSION =	v0.4.6

DISTNAME =	xd-torrent-${MODGO_VERSION}

CATEGORIES =	net

HOMEPAGE =		https://xd-torrent.github.io/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/go
BUILD_DEPENDS =	devel/git

SEPARATE_BUILD =	Yes
USE_GMAKE =			Yes

do-build:
	cd ${WRKSRC} && ${MODGO_BUILD}

do-install:
	${INSTALL_PROGRAM} ${WRKBUILD}/XD ${PREFIX}/bin
	ln -s ${PREFIX}/bin/XD ${PREFIX}/bin/XD-CLI
	chmod 755 ${PREFIX}/bin/XD-CLI
	${INSTALL_DATA_DIR} ${SYSCONFDIR}/xd
	${INSTALL_DATA} ${FILESDIR}/*.ini ${SYSCONFDIR}/xd/
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/xd
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/xd/metadata
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/xd/downloads
	${INSTALL_DATA_DIR} ${LOCALSTATEDIR}/xd/seeding

.include "modules.inc"
.include <bsd.port.mk>