COMMENT =	Google Cloud API client core library

MODPY_DISTV =	2.8.0
DISTNAME =	google_cloud_core-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache 2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-google-api-core>=2.28.0,<3.0.0 \
		security/py-google-auth>=2.61.0,<3.0.0

# Version exclusions from upstream metadata (the selected dependencies
# avoid these versions through the reviewed minimum release):
# google-auth!=2.24.0,!=2.25.0,<3.0.0,>=2.14.1

.include <bsd.port.mk>
