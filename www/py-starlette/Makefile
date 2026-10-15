COMMENT =		lightweight ASGI library

MODPY_DISTV =	1.7.0

DISTNAME =	starlette-${MODPY_DISTV}
PKGNAME =		py-${DISTNAME}
REVISION =       0

CATEGORIES =		www

HOMEPAGE =		https://www.starlette.io/

# BSD
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =	hatchling

# XXX: needs httpx2
TEST_DEPENDS =		devel/py-trio \
			textproc/py-yaml \
			www/py-httpx \
			www/py-itsdangerous \
			www/py-jinja2 \
			www/py-python-multipart

RUN_DEPENDS =	net/py-anyio>=4.0.0,<5

TEST_DEPENDS += devel/py-blockbuster
# The optional OpenTelemetry SDK is not ported.
MODPY_PYTEST_ARGS = --ignore=tests/middleware/test_opentelemetry.py

.include <bsd.port.mk>
