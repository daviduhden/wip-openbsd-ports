COMMENT =	A python wrapper of the C library 'Google CRC32C'

MODPY_DISTV =	1.9.0
DISTNAME =	google_crc32c-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

COMPILER =	base-clang ports-gcc
COMPILER_LANGS =	c
LIB_DEPENDS =	devel/crc32c
WANTLIB +=	crc32c
MAKE_ENV +=	CRC32C_INSTALL_PREFIX=${LOCALBASE} CRC32C_PURE_PYTHON=0

.include <bsd.port.mk>
