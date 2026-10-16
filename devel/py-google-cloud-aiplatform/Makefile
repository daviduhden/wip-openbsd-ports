COMMENT =	Vertex AI API client library

MODPY_DISTV =	2.5.0
DISTNAME =	google_cloud_aiplatform-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache 2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-certifi>=2023.7.22 \
		devel/py-docstring-parser<1 \
		devel/py-google-api-core>=2.42.0,<3.0.0 \
		devel/py-google-cloud-bigquery>=3.46.1,<4.0.0 \
		devel/py-google-cloud-resource-manager>=1.3.3,<3.0.0 \
		devel/py-google-cloud-storage>=3.10.0,<4.0.0 \
		devel/py-google-genai>=1.66.0,<3.0.0 \
		devel/py-proto-plus>=1.22.3,<2.0.0 \
		devel/py-protobuf>=6.33.6,<7.0.0 \
		devel/py-pydantic<3 \
		devel/py-typing-extensions \
		security/py-google-auth>=2.47.0,<3.0.0 \
		sysutils/py-packaging>=14.3

# Version exclusions from upstream metadata (the selected dependencies
# avoid these versions through the reviewed minimum release):
# google-api-core[grpc]!=2.0.*,!=2.1.*,!=2.2.*,!=2.3.*,!=2.4.*,!=2.5.*,!=2.6.*,!=2.7.*,<3.0.0,>=1.34.1
# google-cloud-bigquery!=3.20.0,<4.0.0,>=1.15.0
# protobuf!=4.21.0,!=4.21.1,!=4.21.2,!=4.21.3,!=4.21.4,!=4.21.5,<7.0.0,>=3.20.2

# Test the core generated clients; optional ML framework suites need extras.
MODPY_PYTEST_ARGS = -n 4 tests/unit/gapic
TEST_DEPENDS += devel/py-test-xdist

.include <bsd.port.mk>
