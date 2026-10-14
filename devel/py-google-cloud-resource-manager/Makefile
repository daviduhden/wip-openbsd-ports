COMMENT =	Google Cloud Resource Manager API client library

MODPY_DISTV =	1.19.0
DISTNAME =	google_cloud_resource_manager-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-google-api-core>=2.28.0,<3.0.0 \
		devel/py-proto-plus>=1.26.1,<2.0.0 \
		devel/py-protobuf>=6.33.5,<8.0.0 \
		net/py-grpc-google-iam-v1>=0.14.2,<1.0.0 \
		net/py-grpcio>=1.59.0,>=1.75.1,<2.0.0 \
		security/py-google-auth>=2.61.0,<3.0.0

# Version exclusions from upstream metadata (the selected dependencies
# avoid these versions through the reviewed minimum release):
# google-auth!=2.24.0,!=2.25.0,<3.0.0,>=2.14.1

MODPY_PYTEST_ARGS =	tests/unit

.include <bsd.port.mk>
