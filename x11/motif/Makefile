COMMENT=	Motif toolkit

GH_ACCOUNT=	thentenaar
GH_PROJECT=	motif
GH_TAGNAME=	v2.5.2

SHARED_LIBS +=  Xm                   6.3      # 5.1
SHARED_LIBS +=  Mrm                  4.3      # 5.1
SHARED_LIBS +=  Uil                  5.2      # 5.1

CATEGORIES=	x11
HOMEPAGE=	https://github.com/thentenaar/motif

# LGPLv2.1
PERMIT_PACKAGE=	Yes

WANTLIB=  ICE SM X11 Xfixes Xcursor Xext Xft Xmu Xpm Xrandr Xrender Xt c expat
WANTLIB+= fontconfig freetype iconv jpeg m png pthread xcb z

LIB_DEPENDS=	converters/libiconv \
		graphics/jpeg \
		graphics/png

# autoreconf runs autopoint even though the tree does not use gettext
BUILD_DEPENDS=	devel/gettext,-tools

USE_GROFF=	Yes

CONFIGURE_STYLE=autoreconf
AUTORECONF=	./autogen.sh
AUTOCONF_VERSION=	2.73
AUTOMAKE_VERSION=	1.16
CONFIGURE_ARGS=	--with-xft \
		--with-jpeg \
		--with-png \
		--enable-demos
CONFIGURE_ENV=	CPPFLAGS='-I${X11BASE}/include -I${LOCALBASE}/include' \
		LDFLAGS='-L${LOCALBASE}/lib'

post-install:
# fix sections
	cd ${PREFIX}/man/man1 && sed -i '/^\.TH/s|user cmd|1|' *.1
	cd ${PREFIX}/man/man3 && sed -i '/^\.TH/s|library call|3|' *.3
	cd ${PREFIX}/man/man4 && sed -i '/^\.TH/s|special file|5|' *.4
	cd ${PREFIX}/man/man5 && sed -i '/^\.TH/s|file formats|5|' *.5
	mv ${PREFIX}/man/man4/mwmrc.4 ${PREFIX}/man/man5/mwmrc.5
# demo programs
	mv ${PREFIX}/share/Xm ${PREFIX}/lib/Xm

.include <bsd.port.mk>
