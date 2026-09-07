COMMENT=	multiple virtual desktop window manager

VERSION=	1.1.5
DISTNAME=	fvwm3-${VERSION}

CATEGORIES=     x11

HOMEPAGE=	https://www.fvwm.org/

MAINTAINER=	Michael <michi+openbsd@dataswamp.org>

# Mostly GPLv2, main module has some code under MIT
# See COPYING and https://github.com/fvwmorg/fvwm/commit/cadd6ed0d5
PERMIT_PACKAGE=	Yes

WANTLIB += ICE SM X11 Xcursor Xext Xfixes Xft Xrandr Xpm Xrender
WANTLIB += c cairo fontconfig gobject-2.0 iconv intl m png
WANTLIB += rsvg-2 event_core

SITES=		https://github.com/fvwmorg/fvwm3/releases/download/${VERSION}/

BUILD_DEPENDS+=	textproc/asciidoctor \
		devel/gettext,-tools

LIB_DEPENDS+=	graphics/png \
		x11/gnome/librsvg \
		devel/libevent2

SUBST_VARS=	VERSION

CONFIGURE_STYLE=	meson
MODULES +=		devel/meson

CONFIGURE_ARGS+=	-Dmandoc=true \
			-Dbidi=disabled \
			-Dgolang=disabled \
			-Dlocaledir=${TRUEPREFIX}/share/fvwm3/locale

CONFIGURE_ENV+=		CPPFLAGS="${CPPFLAGS} -I${LOCALBASE}/include" \
			LDFLAGS="${LDFLAGS} -L${LOCALBASE}/lib"

DEBUG_PACKAGES =       ${BUILD_PACKAGES}

USE_GMAKE =	yes

post-install:
	cd ${WRKINST}/${TRUEPREFIX}/man/man1 && for m in Fvwm*.1; \
		do mv {,fvwm3-}$$m; done
	cd ${WRKINST}/${TRUEPREFIX}/man/man1 && for m in \
		fvwm-convert-2.6.1 fvwm-menu-desktop.1 fvwm-menu-directory.1 \
		fvwm-menu-xlock.1 fvwm-perllib.1 fvwm-root.1; do \
		mv $$m fvwm3-$${m#fvwm-}; done
	cd ${WRKINST}/${TRUEPREFIX}/man/man1/ && \
		mv fvwm3-FvwmCommand{,3}.1
	cd ${WRKINST}/${TRUEPREFIX}/bin && for b in \
		fvwm-convert-2.6 fvwm-menu-desktop fvwm-menu-directory \
		fvwm-menu-xlock fvwm-perllib fvwm-root; do \
		mv $$b fvwm3-$${b#fvwm-}; done
	mv ${WRKINST}/${TRUEPREFIX}/bin/FvwmCommand{,3}

.include <bsd.port.mk>

.if ${CHOSEN_COMPILER} == "base-clang"
CFLAGS+=		-Wno-error=int-conversion
.endif
