COMMENT =	ASGI lifespan protocol helpers

MODPY_DISTV =	2.1.0
DISTNAME =	asgi-lifespan-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	www
HOMEPAGE =	https://github.com/florimondmanca/asgi-lifespan

# MIT
PERMIT_PACKAGE = Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools_scm

RUN_DEPENDS =	devel/py-sniffio
TEST_DEPENDS =	devel/py-test-asyncio \
		devel/py-test-trio \
		devel/py-test-cov \
		devel/py-trio \
		www/py-starlette \
		www/py-httpx

MODPY_PYTEST_ARGS = --cov-reset --cov=asgi_lifespan --cov=tests

.include <bsd.port.mk>
