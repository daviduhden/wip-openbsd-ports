COMMENT =		SSE plugin for Starlette

MODPY_DISTV =	3.5.0

DISTNAME =	sse_starlette-${MODPY_DISTV}
PKGNAME =		py-${DISTNAME}

CATEGORIES =		www

# BSD
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	net/py-anyio>=4.7.0 \
		www/py-starlette>=0.49.1

.include <bsd.port.mk>
