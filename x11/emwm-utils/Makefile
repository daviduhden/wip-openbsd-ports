COMMENT=	utilities for Enhanced Motif Window Manager

DISTNAME=	emwm-utils-src-2.0
PKGNAME=	emwm-utils-2.0

CATEGORIES=	x11
HOMEPAGE=	https://fastestcode.org/emwm.html

SITES=		https://fastestcode.org/dl/
SITES.misc=	https://fastestcode.org/misc/

DISTFILES=	${DISTNAME}${EXTRACT_SUFX} \
		tellmwm-src-20260721{tellmwm-src}.tar.xz \
		app-icons-20250710{app-icons}.tar.xz \
		xc-core-hr-20241226{xc-core-hr}.tar.xz \
		xmdlgicons-20250717{xmdlgicons}.tar.xz \
		gtk-configs.tar.xz
DISTFILES.misc=	Xresources-sample
DIST_SUBDIR=	emwm-utils
EXTRACT_SUFX=	.tar.xz
EXTRACT_ONLY=	emwm-utils-src-2.0.tar.xz \
		tellmwm-src-20260721.tar.xz \
		app-icons-20250710.tar.xz \
		xc-core-hr-20241226.tar.xz \
		xmdlgicons-20250717.tar.xz \
		gtk-configs.tar.xz

# emwm-utils: MIT; tellmwm: permissive; artwork: CC BY-SA 3.0;
# gtk-configs and Xresources-sample: public domain.
PERMIT_PACKAGE=	Yes

WANTLIB += X11 Xinerama Xrandr Xss Xt Xm c

LIB_DEPENDS=	x11/motif
BUILD_DEPENDS=	x11/xcursorgen
RUN_DEPENDS=	x11/emwm>=2.0

WRKDIST=	${WRKDIR}/emwm-utils-src-2.0

# run shutdown(8)/zzz(8) with the invoking user's privileges; bsd.port.mk
# also appends its own CFLAGS to MAKE_ENV, so putting the define in MAKE_ENV
# would be overridden
CFLAGS +=	-DUNPRIVILEGED_SHUTDOWN

MAKE_ENV=	CC='${CC}' \
		LDFLAGS='${LDFLAGS}'

MAKE_FLAGS=	PREFIX='${PREFIX}' \
		MANDIR='${PREFIX}/man' \
		RCDIR='${PREFIX}/lib/X11' \
		APPLRESDIR='${PREFIX}/lib/X11/app-defaults' \
		INCDIRS='-I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE_PROGRAM} ${MAKE_FLAGS} OpenBSD
	cd ${WRKDIR}/tellmwm && ${CC} ${CFLAGS} \
		-I${X11BASE}/include -I${LOCALBASE}/include \
		-c tellmwm.c -o tellmwm.o
	cd ${WRKDIR}/tellmwm && ${CC} ${CFLAGS} \
		-I${X11BASE}/include -I${LOCALBASE}/include \
		-c wsmutil.c -o wsmutil.o
	cd ${WRKDIR}/tellmwm && ${CC} ${LDFLAGS} \
		-L${X11BASE}/lib -L${LOCALBASE}/lib \
		-o tellmwm tellmwm.o wsmutil.o -lX11
	cd ${WRKDIR}/xc-core-hr && ${SETENV} ${MAKE_ENV} \
		/bin/sh ./build.sh core-hr

do-install:
	${INSTALL_SCRIPT} ${WRKSRC}/src/xmsession ${PREFIX}/bin/xmsession
	${INSTALL_PROGRAM} ${WRKDIR}/tellmwm/tellmwm ${PREFIX}/bin/tellmwm
	${INSTALL_PROGRAM} ${WRKSRC}/src/xmtoolbox ${PREFIX}/bin/xmtoolbox
	${INSTALL_PROGRAM} ${WRKSRC}/src/xmsm ${PREFIX}/bin/xmsm
	${INSTALL_MAN} ${WRKDIR}/tellmwm/tellmwm.1 \
		${PREFIX}/man/man1/tellmwm.1
	${INSTALL_MAN} ${WRKSRC}/src/xmtoolbox.1 ${PREFIX}/man/man1/xmtoolbox.1
	${INSTALL_MAN} ${WRKSRC}/src/xmsm.1 ${PREFIX}/man/man1/xmsm.1
	${INSTALL_DATA} ${WRKSRC}/src/XmSm.ad \
		${PREFIX}/lib/X11/app-defaults/XmSm
	${INSTALL_DATA} ${WRKSRC}/src/XmToolbox.ad \
		${PREFIX}/lib/X11/app-defaults/XmToolbox
	${INSTALL_DATA} ${WRKSRC}/src/toolboxrc ${PREFIX}/lib/X11/toolboxrc
	${INSTALL_DATA_DIR} ${PREFIX}/share/emwm/icons
	${INSTALL_DATA} ${WRKDIR}/icons/*.xpm ${PREFIX}/share/emwm/icons/
	${INSTALL_DATA_DIR} ${PREFIX}/share/icons/core-hr/cursors
	for f in ${WRKDIR}/xc-core-hr/core-hr/cursors/*; do \
		if test -L $$f; then \
			ln -s $$(readlink $$f) \
			    ${PREFIX}/share/icons/core-hr/cursors/$${f##*/}; \
		else \
			${INSTALL_DATA} $$f \
			    ${PREFIX}/share/icons/core-hr/cursors/; \
		fi; \
	done
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/emwm/xmdlgicons/32px
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/emwm/xmdlgicons/48px
	${INSTALL_DATA} ${WRKDIR}/dlgicons/32px/* \
		${PREFIX}/share/examples/emwm/xmdlgicons/32px/
	${INSTALL_DATA} ${WRKDIR}/dlgicons/48px/* \
		${PREFIX}/share/examples/emwm/xmdlgicons/48px/
	${INSTALL_DATA} ${WRKDIR}/dlgicons/README \
		${PREFIX}/share/examples/emwm/xmdlgicons/
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/emwm/gtk-2.0
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/emwm/gtk-3.0
	${INSTALL_DATA} ${WRKDIR}/gtk-configs/gtkrc-2.0 \
		${PREFIX}/share/examples/emwm/gtk-2.0/
	${INSTALL_DATA} ${WRKDIR}/gtk-configs/gtk.css \
		${PREFIX}/share/examples/emwm/gtk-3.0/
	${INSTALL_DATA} ${FULLDISTDIR}/Xresources-sample \
		${PREFIX}/share/examples/emwm/Xresources
	${INSTALL_DATA_DIR} ${PREFIX}/share/doc/emwm-utils
	${INSTALL_DATA} ${WRKDIR}/tellmwm/COPYING \
		${PREFIX}/share/doc/emwm-utils/COPYING.tellmwm
	${INSTALL_DATA} ${WRKDIR}/tellmwm/README \
		${PREFIX}/share/doc/emwm-utils/README.tellmwm
	${INSTALL_DATA} ${WRKDIR}/icons/COPYING \
		${PREFIX}/share/doc/emwm-utils/COPYING.app-icons
	${INSTALL_DATA} ${WRKDIR}/xc-core-hr/COPYING \
		${PREFIX}/share/doc/emwm-utils/COPYING.xc-core-hr
	${INSTALL_DATA} ${WRKDIR}/xc-core-hr/README \
		${PREFIX}/share/doc/emwm-utils/README.xc-core-hr

NO_TEST=	Yes

.include <bsd.port.mk>
