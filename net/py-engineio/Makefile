COMMENT=	client/server implementation of Engine.IO

MODPY_DISTV=	4.13.3
DISTNAME=	python_engineio-${MODPY_DISTV}
PKGNAME=	py-engineio-${MODPY_DISTV}

CATEGORIES=	net
HOMEPAGE=	https://python-engineio.readthedocs.io/en/latest/

# MIT
PERMIT_PACKAGE=	Yes

MODULES=	lang/python
MODPY_PYBUILD=	setuptools
MODPY_PI=	Yes
NO_TEST=	Yes

RUN_DEPENDS=	net/py-websocket-client \
		www/py-requests \
		www/py-simple-websocket>=0.10

.include <bsd.port.mk>
