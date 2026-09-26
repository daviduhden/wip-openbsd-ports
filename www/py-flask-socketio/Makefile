COMMENT=	Socket.IO integration for Flask

MODPY_DISTV=	5.6.1
DISTNAME=	flask_socketio-${MODPY_DISTV}
PKGNAME=	py-flask-socketio-${MODPY_DISTV}

CATEGORIES=	www
HOMEPAGE=	https://flask-socketio.readthedocs.io/

# MIT
PERMIT_PACKAGE=	Yes

MODULES=	lang/python
MODPY_PYBUILD=	setuptools
MODPY_PI=	Yes
NO_TEST=	Yes

RUN_DEPENDS=	net/py-socketio \
		www/py-flask

.include <bsd.port.mk>
