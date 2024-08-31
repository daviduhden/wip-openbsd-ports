COMMENT =	handy tool to trash your metadata

VERSION = 0.13.4
MODPY_EGG_VERSION =	${VERSION}

DISTNAME =	mat2-${VERSION}
EXTRACT_SUFX=	.tar.gz
DISTFILES =	mat2-${VERSION}${EXTRACT_SUFX}

CATEGORIES =	sysutils

HOMEPAGE =	https://0xacab.org/jvoisin/mat2

# GPLv3+
PERMIT_PACKAGE =	Yes

SITES =		https://0xacab.org/jvoisin/mat2/-/archive/${VERSION}/

MODULES =	lang/python

MODPY_SETUPTOOLS =	Yes

BUILD_DEPENDS=		devel/py-gobject3${MODPY_FLAVOR}

LIB_DEPENDS =	audio/py-mutagen${MODPY_FLAVOR} \
				graphics/py-cairo${MODPY_FLAVOR} \
				print/poppler \
				graphics/gdk-pixbuf2 \
				graphics/ffmpeg \
				graphics/p5-Image-ExifTool

.include <bsd.port.mk>