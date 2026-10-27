COMMENT =	Status proto mapping for gRPC

MODPY_DISTV =	1.85.0
DISTNAME =	grpcio_status-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	net

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-protobuf>=6.33.5,<8.0.0 \
		net/py-googleapis-common-protos>=1.5.5 \
		net/py-grpcio>=1.85.0

# No tests in the PyPI sdist.
NO_TEST =	Yes

.include <bsd.port.mk>
