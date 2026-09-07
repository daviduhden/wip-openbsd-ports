COMMENT=		fast, compact Motif/X11 plain text editor (classic fork)

COMMIT_ID=	dd408440cb392db2258edfef753c57e134cfbbd8
DISTNAME=	nedit-classic-5.7.20260411
PKGNAME=	nedit-5.7.20260411

CATEGORIES=	editors x11
HOMEPAGE=	https://github.com/alx210/nedit-classic
MAINTAINER=	Alessandro De Laurenzis <just22@atlantide.mooo.com>

SITES=		https://github.com/alx210/nedit-classic/archive/
DISTFILES=	${COMMIT_ID}.tar.gz

WRKDIST=	${WRKDIR}/nedit-classic-${COMMIT_ID}

# GPLv2
PERMIT_PACKAGE=	Yes

WANTLIB += ICE SM X11 Xau Xdmcp Xext Xft Xmu Xpm Xrender Xt
WANTLIB += c expat fontconfig freetype iconv m z Xm

LIB_DEPENDS+=	converters/libiconv \
		x11/motif

ALL_TARGET=	openbsd

post-build:
	/usr/bin/pod2man --section=1 ${WRKSRC}/doc/nedit.pod ${WRKSRC}/doc/nedit.man
	/usr/bin/pod2man --section=1 ${WRKSRC}/doc/nc.pod ${WRKSRC}/doc/nc.man

NO_TEST=	Yes

MAKE_ENV+=	MOTIFLIB='-L${LOCALBASE}/lib -lXm' \
		LOCALBASE='${LOCALBASE}' \
		X11BASE='${X11BASE}'

do-install:
	sed -i "s/^\.TH NC/&L/" ${WRKSRC}/doc/nc.man
	${INSTALL_PROGRAM} ${WRKBUILD}/source/nedit ${PREFIX}/bin/nedit
	${INSTALL_PROGRAM} ${WRKBUILD}/source/nc ${PREFIX}/bin/ncl
	${INSTALL_MAN} ${WRKSRC}/doc/nedit.man ${PREFIX}/man/man1/nedit.1
	${INSTALL_MAN} ${WRKSRC}/doc/nc.man ${PREFIX}/man/man1/ncl.1
	${INSTALL_DATA} ${WRKSRC}/doc/NEdit.ad \
		${PREFIX}/lib/X11/app-defaults/NEdit

.include <bsd.port.mk>
