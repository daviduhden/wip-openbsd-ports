COMMENT =		SSE plugin for Starlette

MODPY_DISTV =	3.6.0

DISTNAME =	sse_starlette-${MODPY_DISTV}
PKGNAME =		py-${DISTNAME}

CATEGORIES =		www

# BSD
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

DISTFILES = ${GH_DISTFILE}
GH_ACCOUNT = sysid
GH_PROJECT = sse-starlette
GH_TAGNAME = v${MODPY_DISTV}
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	net/py-anyio>=4.7.0 \
		www/py-starlette>=0.49.1

TEST_DEPENDS = www/py-asgi-lifespan \
	devel/py-test-asyncio \
	www/py-httpx2 \
	www/py-uvicorn

# Integration and experimentation suites require Docker.
MODPY_PYTEST_ARGS = tests/test_*.py

.include <bsd.port.mk>
