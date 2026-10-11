COMMENT =	Utilities for Google Media Downloads and Resumable Uploads

MODPY_DISTV =	2.11.0
DISTNAME =	google_resumable_media-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache 2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-google-crc32c>=1.0.0,<2.0.0

.include <bsd.port.mk>
