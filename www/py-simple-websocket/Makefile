COMMENT=	simple WebSocket server and client

MODPY_DISTV=	1.1.0
DISTNAME=	simple_websocket-${MODPY_DISTV}
PKGNAME=	py-simple-websocket-${MODPY_DISTV}

CATEGORIES=	www
HOMEPAGE=	https://github.com/miguelgrinberg/simple-websocket

# MIT
PERMIT_PACKAGE=	Yes

MODULES=	lang/python
MODPY_PYBUILD=	setuptools
MODPY_PI=	Yes
NO_TEST=	Yes

RUN_DEPENDS=	net/py-wsproto

.include <bsd.port.mk>
