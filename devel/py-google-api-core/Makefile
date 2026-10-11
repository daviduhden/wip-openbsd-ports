COMMENT =	Google API client core library

MODPY_DISTV =	2.42.0
DISTNAME =	google_api_core-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache 2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-opentelemetry-api>=1.44.0,<2.0.0 \
		devel/py-proto-plus>=1.26.1,<2.0.0 \
		devel/py-protobuf>=6.33.5,<8.0.0 \
		net/py-googleapis-common-protos>=1.69.2,<2.0.0 \
		net/py-grpcio>=1.59.0,>=1.75.1,<2.0.0 \
		net/py-grpcio-status>=1.59.0,>=1.75.1,<2.0.0 \
		security/py-google-auth>=2.14.1,<3.0.0 \
		www/py-requests>=2.33.0,<3.0.0

.include <bsd.port.mk>
