COMMENT =		HTTP client for Python

MODPY_DISTV =		2.13.0
DISTNAME =		httpx2-${MODPY_DISTV}
PKGNAME =		py-httpx2-${MODPY_DISTV}

CATEGORIES =		www

HOMEPAGE =		https://github.com/pydantic/httpx2

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =		hatchling

BUILD_DEPENDS =		devel/py-hatch-fancy-pypi-readme \
			devel/py-uv-dynamic-versioning

RUN_DEPENDS =		net/py-anyio \
			net/py-idna \
			security/py-truststore \
			www/py-httpcore2

.include <bsd.port.mk>
