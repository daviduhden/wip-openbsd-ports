COMMENT =	multiple virtual desktop window manager

VERSION =	1.1.5
DISTNAME =	fvwm3-${VERSION}
REVISION =       0

CATEGORIES =     x11

HOMEPAGE =	https://www.fvwm.org/

MAINTAINER =	Michael <michi+openbsd@dataswamp.org>

# Mostly GPLv2, main module has some code under MIT
# See COPYING and https://github.com/fvwmorg/fvwm/commit/cadd6ed0d5
PERMIT_PACKAGE =	Yes

WANTLIB += ICE SM X11 Xcursor Xext Xfixes Xft Xrandr Xpm Xrender
WANTLIB += c cairo fontconfig gobject-2.0 iconv intl m png
WANTLIB += rsvg-2 event_core

SITES =		https://github.com/fvwmorg/fvwm3/releases/download/${VERSION}/

BUILD_DEPENDS +=	textproc/asciidoctor \
		devel/gettext,-tools

LIB_DEPENDS +=	graphics/png \
		x11/gnome/librsvg \
		devel/libevent2

SUBST_VARS =	VERSION

CONFIGURE_STYLE =	meson
MODULES +=		devel/meson

CONFIGURE_ARGS +=	-Dmandoc=true \
			-Dbidi=disabled \
			-Dgolang=disabled \
			-Dlocaledir=${TRUEPREFIX}/share/fvwm3/locale

CONFIGURE_ENV +=		CPPFLAGS="${CPPFLAGS} -I${LOCALBASE}/include" \
			LDFLAGS="${LDFLAGS} -L${LOCALBASE}/lib"

DEBUG_PACKAGES =       ${BUILD_PACKAGES}

USE_GMAKE =	yes

post-install:
	sh ${FILESDIR}/rename-paths.sh "${WRKINST}${TRUEPREFIX}"

# bsd.port.mk converts CFLAGS_<chosen compiler> into CFLAGS. Assigning
# CFLAGS after the include would be too late for the build environment.
CFLAGS_base-clang =	-Wno-error=int-conversion

.include <bsd.port.mk>
