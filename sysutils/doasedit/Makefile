BROKEN =		privileged path races require an upstream redesign

COMMENT =		edit root-owned files using an unprivileged editor

V =			1.0.9
DISTNAME =		doasedit-${V}
CATEGORIES =		sysutils
HOMEPAGE =		https://codeberg.org/TotallyLeGIT/doasedit
SITES =			${HOMEPAGE}/archive/
DISTFILES =		${DISTNAME}{${V}}.tar.gz

# MIT
PERMIT_PACKAGE =	Yes

NO_BUILD =		Yes
NO_TEST =		Yes
PKG_ARCH =		*
WRKDIST =		${WRKDIR}/doasedit

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/doasedit ${PREFIX}/bin/
	${INSTALL_MAN} ${WRKSRC}/doasedit.1 ${PREFIX}/man/man1/
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/doasedit
	${INSTALL_DATA} ${WRKSRC}/LICENSE \
		${PREFIX}/share/doc/doasedit/

.include <bsd.port.mk>
