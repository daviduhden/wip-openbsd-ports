COMMENT =	IAM API client library

MODPY_DISTV =	0.14.5
DISTNAME =	grpc_google_iam_v1-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	net

# Apache 2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-protobuf>=6.33.5,<8.0.0 \
		net/py-googleapis-common-protos>=1.69.2,<2.0.0 \
		net/py-grpcio>=1.59.0,<2.0.0

.include <bsd.port.mk>
