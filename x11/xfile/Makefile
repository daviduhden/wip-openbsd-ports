COMMENT =	compact file manager for Unix/X11 Motif

DISTNAME =	xfile-src-1.2.1
PKGNAME =	xfile-1.2.1

CATEGORIES =	x11
HOMEPAGE =	https://fastestcode.org/xfile.html

SITES =		https://fastestcode.org/dl/
DIST_SUBDIR =	xfile
DISTFILES =	xfile-src-1.2.1.tar.xz \
		xfile-addon-20260806{xfile-addon}.tar.xz \
		xfile-slanted-icons-20241226{xfile-slanted-icons}.tar.xz \
		xfile-xdgsvc-src-20241226{xfile-xdgsvc-src}.tar.xz \
		xfind-src-20260804{xfind-src}.tar.xz
EXTRACT_SUFX =	.tar.xz

# MIT (xfind and the data addons carry permissive terms from the same
# author, see pkg/DESCR)
PERMIT_PACKAGE =	Yes

WANTLIB += X11 Xinerama Xpm Xt Xm c dbus-1 m

LIB_DEPENDS =	x11/dbus x11/motif

WRKDIST =	${WRKDIR}/xfile-src-1.2.1

MAKE_ENV =	CC='${CC}' \
		CFLAGS='${CFLAGS}' \
		LDFLAGS='${LDFLAGS}'

MAKE_FLAGS =	PREFIX='${PREFIX}' \
		MANDIR='${PREFIX}/man' \
		SHAREDIR='${PREFIX}/share/xfile' \
		APPLRESDIR='${PREFIX}/lib/X11/app-defaults' \
		INCDIRS='-I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

XFIND_FLAGS =	CC='${CC}' \
		CFLAGS='${CFLAGS} -I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

XDGSVC_FLAGS =	CC='${CC}' \
		CFLAGS='${CFLAGS} -I${LOCALBASE}/include/dbus-1.0 -I${LOCALBASE}/lib/dbus-1.0/include' \
		LIBDIRS='-L${LOCALBASE}/lib'

# keep everything under WRKDIST so that patches and build/install targets
# do not have to reference ${WRKDIR} siblings, which are not always
# reachable from within the framework
post-extract:
	mv ${WRKDIR}/xfile-addon ${WRKSRC}/
	mv ${WRKDIR}/xfile-xdgsvc ${WRKSRC}/
	mv ${WRKDIR}/xfind ${WRKSRC}/
	mv ${WRKDIR}/slanted-icons ${WRKSRC}/

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MAKE_PROGRAM} ${MAKE_FLAGS} OpenBSD
	cd ${WRKSRC}/xfind && ${SETENV} ${MAKE_ENV} ${MAKE_PROGRAM} ${XFIND_FLAGS} xfind
	cd ${WRKSRC}/xfile-xdgsvc && ${SETENV} ${MAKE_ENV} ${MAKE_PROGRAM} ${XDGSVC_FLAGS} xfile-xdgsvc

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/src/xfile ${PREFIX}/bin/xfile
	ln -s xfile ${PREFIX}/bin/xfile-open
	${INSTALL_MAN} ${WRKSRC}/src/xfile.1 ${PREFIX}/man/man1/xfile.1
	${INSTALL_DATA} ${WRKSRC}/src/xfile.ad \
		${PREFIX}/lib/X11/app-defaults/XFile
	${INSTALL_PROGRAM} ${WRKSRC}/xfind/xfind ${PREFIX}/bin/xfind
	${INSTALL_MAN} ${WRKSRC}/xfind/xfind.man ${PREFIX}/man/man1/xfind.1
	${INSTALL_DATA} ${WRKSRC}/xfind/XFind.ad \
		${PREFIX}/lib/X11/app-defaults/XFind
	${INSTALL_PROGRAM} ${WRKSRC}/xfile-xdgsvc/xfile-xdgsvc \
		${PREFIX}/bin/xfile-xdgsvc
	env WRKSRC=${WRKSRC} PREFIX=${PREFIX} TRUEPREFIX=${TRUEPREFIX} \
		INSTALL_DATA="${INSTALL_DATA}" \
		INSTALL_DATA_DIR="${INSTALL_DATA_DIR}" \
		sh ${FILESDIR}/install-data.sh

NO_TEST =	Yes

.include <bsd.port.mk>
