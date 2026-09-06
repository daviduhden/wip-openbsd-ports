COMMENT=	enhanced motif window manager (MWM fork)

V=		2.1
DISTNAME=	emwm-src-${V}
PKGNAME=	emwm-${V}

CATEGORIES=	x11
HOMEPAGE=	https://fastestcode.org/emwm.html

SITES=		https://fastestcode.org/dl/
EXTRACT_SUFX=	.tar.xz

# LGPL v2.1
PERMIT_PACKAGE=	Yes

WANTLIB += X11 Xext Xinerama Xm Xrandr Xt c m

LIB_DEPENDS=	x11/motif

WRKDIST=	${WRKDIR}/emwm-src-${V}

MAKE_ENV=	CC='${CC}' \
		CFLAGS='${CFLAGS}' \
		LDFLAGS='${LDFLAGS}'

MAKE_FLAGS=	PREFIX='${PREFIX}' \
		MANDIR='${PREFIX}/man' \
		RCDIR='${PREFIX}/lib/X11' \
		APPLRESDIR='${PREFIX}/lib/X11/app-defaults' \
		INCDIRS='-I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} \
		${MAKE_PROGRAM} ${MAKE_FLAGS} OpenBSD

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/src/emwm ${PREFIX}/bin/emwm
	${INSTALL_MAN} ${WRKSRC}/src/emwm.1 ${PREFIX}/man/man1/emwm.1
	${INSTALL_MAN} ${WRKSRC}/src/emwmrc.4 ${PREFIX}/man/man4/emwmrc.4
	${INSTALL_DATA} ${WRKSRC}/src/Emwm.ad \
		${PREFIX}/lib/X11/app-defaults/Emwm
	${INSTALL_DATA} ${WRKSRC}/src/system.emwmrc \
		${PREFIX}/lib/X11/system.emwmrc

NO_TEST=	Yes

.include <bsd.port.mk>
