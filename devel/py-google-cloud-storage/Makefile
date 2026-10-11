COMMENT =	Google Cloud Storage API client library

MODPY_DISTV =	3.17.0
DISTNAME =	google_cloud_storage-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-google-api-core>=2.27.0,<3.0.0 \
		devel/py-google-cloud-core>=2.4.2,<3.0.0 \
		devel/py-google-crc32c>=1.6.0,<2.0.0 \
		devel/py-google-resumable-media>=2.7.2,<3.0.0 \
		security/py-google-auth>=2.26.1,<3.0.0 \
		www/py-requests>=2.22.0,<3.0.0

.include <bsd.port.mk>
