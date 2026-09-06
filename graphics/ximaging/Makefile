COMMENT=	lightweight image viewer and browser for Unix/X11 Motif

DISTNAME=	ximaging-src-1.9.2
PKGNAME=	ximaging-1.9.2

CATEGORIES=	graphics x11
HOMEPAGE=	https://fastestcode.org/ximaging.html

SITES=		https://fastestcode.org/dl/
EXTRACT_SUFX=	.tar.xz

# MIT
PERMIT_PACKAGE=	Yes

WANTLIB += X11 Xinerama Xt Xm c jpeg m png pthread tiff

LIB_DEPENDS=	graphics/jpeg \
		graphics/png \
		graphics/tiff \
		x11/motif

RUN_DEPENDS=	graphics/ImageMagick

WRKDIST=	${WRKDIR}/ximaging-src-1.9.2

MAKE_ENV=	CC='${CC}' \
		CFLAGS='${CFLAGS}' \
		LDFLAGS='${LDFLAGS}'

MAKE_FLAGS=	PREFIX='${PREFIX}' \
		ENABLE_OMP=0 \
		MANDIR='${PREFIX}/man' \
		APPLRESDIR='${PREFIX}/lib/X11/app-defaults' \
		INCDIRS='-I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE_PROGRAM} ${MAKE_FLAGS} OpenBSD

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/src/ximaging ${PREFIX}/bin/ximaging
	${INSTALL_MAN} ${WRKSRC}/src/ximaging.1 ${PREFIX}/man/man1/ximaging.1
	${INSTALL_DATA} ${WRKSRC}/src/XImaging.ad \
		${PREFIX}/lib/X11/app-defaults/XImaging

NO_TEST=	Yes

.include <bsd.port.mk>
