COMMENT=	compact file manager for Unix/X11 Motif

DISTNAME=	xfile-src-1.2.1
PKGNAME=	xfile-1.2.1

CATEGORIES=	x11
HOMEPAGE=	https://fastestcode.org/xfile.html

SITES=		https://fastestcode.org/dl/
DIST_SUBDIR=	xfile
DISTFILES=	xfile-src-1.2.1.tar.xz \
		xfile-addon-20260806{xfile-addon}.tar.xz \
		xfile-slanted-icons-20241226{xfile-slanted-icons}.tar.xz \
		xfile-xdgsvc-src-20241226{xfile-xdgsvc-src}.tar.xz \
		xfind-src-20260804{xfind-src}.tar.xz
EXTRACT_SUFX=	.tar.xz

# MIT (xfind and the data addons carry permissive terms from the same
# author, see pkg/DESCR)
PERMIT_PACKAGE=	Yes

WANTLIB += X11 Xinerama Xpm Xt Xm c dbus-1 m

LIB_DEPENDS=	x11/dbus x11/motif

WRKDIST=	${WRKDIR}/xfile-src-1.2.1

MAKE_ENV=	CC='${CC}' \
		CFLAGS='${CFLAGS}' \
		LDFLAGS='${LDFLAGS}'

MAKE_FLAGS=	PREFIX='${PREFIX}' \
		MANDIR='${PREFIX}/man' \
		SHAREDIR='${PREFIX}/share/xfile' \
		APPLRESDIR='${PREFIX}/lib/X11/app-defaults' \
		INCDIRS='-I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

XFIND_FLAGS=	CC='${CC}' \
		CFLAGS='${CFLAGS} -I${X11BASE}/include -I${LOCALBASE}/include' \
		LIBDIRS='-L${X11BASE}/lib -L${LOCALBASE}/lib'

XDGSVC_FLAGS=	CC='${CC}' \
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
	${INSTALL_DATA_DIR} ${PREFIX}/share/xfile/types
	${INSTALL_DATA} ${WRKSRC}/src/default.db \
		${PREFIX}/share/xfile/types/system.db
	${INSTALL_DATA_DIR} ${PREFIX}/share/xfile/icons
	for f in ${WRKSRC}/src/icons/*.xpm; do \
		${INSTALL_DATA} $$f ${PREFIX}/share/xfile/icons/; \
	done
	${INSTALL_DATA} ${WRKSRC}/src/icons/README \
		${PREFIX}/share/xfile/README.icons
	${INSTALL_DATA_DIR} ${PREFIX}/share/pixmaps
	${INSTALL_DATA} ${WRKSRC}/src/xbm/cabinet.xpm \
		${PREFIX}/share/pixmaps/xfile_48x48.xpm
	${INSTALL_DATA} ${WRKSRC}/src/xbm/cabinet64.xpm \
		${PREFIX}/share/pixmaps/xfile_64x64.xpm
	# xfile-addon: additional type definitions and icons.  XFile loads
	# every *.db from share/xfile/types and looks icons up in
	# share/xfile/icons, so these are used automatically; user files
	# in ~/.xfile/{types,icons} still take precedence.
	for f in ${WRKSRC}/xfile-addon/types/*.db; do \
		${INSTALL_DATA} $$f ${PREFIX}/share/xfile/types/; \
	done
	for f in ${WRKSRC}/xfile-addon/icons/*.xpm; do \
		case $$f in *file.[lmst].xpm) continue;; esac; \
		${INSTALL_DATA} $$f ${PREFIX}/share/xfile/icons/; \
	done
	${INSTALL_DATA} ${WRKSRC}/xfile-addon/README \
		${PREFIX}/share/xfile/README.addon
	# alternative "file" icons are shipped as examples only, so they
	# do not override the default icon set
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/xfile/addon/icons
	${INSTALL_DATA} ${WRKSRC}/xfile-addon/icons/file.l.xpm \
		${WRKSRC}/xfile-addon/icons/file.m.xpm \
		${WRKSRC}/xfile-addon/icons/file.s.xpm \
		${WRKSRC}/xfile-addon/icons/file.t.xpm \
		${PREFIX}/share/examples/xfile/addon/icons/
	# xfind
	${INSTALL_PROGRAM} ${WRKSRC}/xfind/xfind ${PREFIX}/bin/xfind
	${INSTALL_MAN} ${WRKSRC}/xfind/xfind.man ${PREFIX}/man/man1/xfind.1
	${INSTALL_DATA} ${WRKSRC}/xfind/XFind.ad \
		${PREFIX}/lib/X11/app-defaults/XFind
	${INSTALL_DATA} ${WRKSRC}/xfind/xfind.xpm \
		${PREFIX}/share/pixmaps/xfind_48x48.xpm
	# xfile-xdgsvc (XDG/freedesktop D-Bus file manager shim)
	${INSTALL_PROGRAM} ${WRKSRC}/xfile-xdgsvc/xfile-xdgsvc \
		${PREFIX}/bin/xfile-xdgsvc
	${INSTALL_DATA_DIR} ${PREFIX}/share/dbus-1/services
	sed 's|^Exec=.*$$|Exec=${TRUEPREFIX}/bin/xfile-xdgsvc|' \
		${WRKSRC}/xfile-xdgsvc/xfile.service > \
		${WRKSRC}/xfile.service
	${INSTALL_DATA} ${WRKSRC}/xfile.service \
		${PREFIX}/share/dbus-1/services/xfile.service
	# optional slanted icons (not selected by default)
	${INSTALL_DATA_DIR} ${PREFIX}/share/examples/xfile/slanted-icons
	for f in ${WRKSRC}/slanted-icons/*.xpm; do \
		${INSTALL_DATA} $$f ${PREFIX}/share/examples/xfile/slanted-icons/; \
	done

NO_TEST=	Yes

.include <bsd.port.mk>
