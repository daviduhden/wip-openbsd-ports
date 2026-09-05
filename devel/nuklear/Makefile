COMMENT =		immediate-mode GUI toolkit in a single C header

GH_ACCOUNT =		Immediate-Mode-UI
GH_PROJECT =		Nuklear
GH_TAGNAME =		v4.13.3
PKGNAME =		nuklear-${GH_TAGNAME:S/v//}
CATEGORIES =		devel

# MIT or public domain; embedded ProggyClean font: MIT
PERMIT_PACKAGE =	Yes

NO_BUILD =		Yes
NO_TEST =		Yes
PKG_ARCH =		*

do-install:
	${INSTALL_DATA} ${WRKSRC}/nuklear.h ${PREFIX}/include/
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/nuklear
	${INSTALL_DATA} ${WRKSRC}/LICENSE \
		${PREFIX}/share/doc/nuklear/

.include <bsd.port.mk>
