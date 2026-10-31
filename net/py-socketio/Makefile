COMMENT =	client/server implementation of Socket.IO

MODPY_DISTV =	5.17.1
DISTNAME =	python_socketio-${MODPY_DISTV}
PKGNAME =	py-socketio-${MODPY_DISTV}

CATEGORIES =	net
HOMEPAGE =	https://python-socketio.readthedocs.io/en/latest/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PYBUILD =	setuptools
MODPY_PI =	Yes
NO_TEST =	Yes

RUN_DEPENDS =	devel/py-bidict>=0.21 \
		net/py-engineio>=4.13.2

.include <bsd.port.mk>
