COMMENT =	Google BigQuery API client library

MODPY_DISTV =	3.47.0
DISTNAME =	google_cloud_bigquery-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache 2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-dateutil>=2.8.2,<3.0.0 \
		devel/py-google-api-core>=2.28.0,<3.0.0 \
		devel/py-google-cloud-core>=2.4.1,<3.0.0 \
		devel/py-google-resumable-media>=2.0.0,<3.0.0 \
		security/py-google-auth>=2.14.1,<3.0.0 \
		sysutils/py-packaging>=24.2.0 \
		www/py-requests>=2.21.0,<3.0.0

MODPY_PYTEST_ARGS =	tests/unit

# The sdist omits the test_utils helper needed by these modules.
MODPY_PYTEST_ARGS += --ignore=tests/unit/test_client.py \
	--ignore=tests/unit/test_magics.py --ignore=tests/unit/test_table.py
.include <bsd.port.mk>
