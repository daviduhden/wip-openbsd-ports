COMMENT=	ASGI web server for Python

MODPY_DISTV =	0.54.0
DISTNAME =	uvicorn-${MODPY_DISTV}
PKGNAME=	py-${DISTNAME}

CATEGORIES=	www

# https://github.com/Kludex/uvicorn
HOMEPAGE=	https://uvicorn.dev/

# BSD
PERMIT_PACKAGE=	Yes

MODULES=	lang/python
MODPY_PYBUILD =	hatchling
MODPY_PI=	Yes

TEST_DEPENDS=	devel/py-test-codspeed \
		devel/py-test-mock \
		devel/py-test-xdist \
		net/py-websockets \
		net/py-wsproto \
		security/py-trustme

RUN_DEPENDS =	devel/py-click>=7.0 \
		www/py-h11>=0.8

TEST_DEPENDS += www/py-httptools
# The optional WSGI adapter a2wsgi is not ported.
MODPY_PYTEST_ARGS = -n 0 --ignore=tests/middleware/test_wsgi.py

.include <bsd.port.mk>
