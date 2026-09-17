COMMENT =		minimal low-level HTTP client library

MODPY_DISTV =		2.13.0
DISTNAME =		httpcore2-${MODPY_DISTV}
PKGNAME =		py-httpcore2-${MODPY_DISTV}

CATEGORIES =		www

HOMEPAGE =		https://github.com/pydantic/httpx2

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =		hatchling

BUILD_DEPENDS =		devel/py-hatch-fancy-pypi-readme \
			devel/py-uv-dynamic-versioning

RUN_DEPENDS =		security/py-truststore \
			www/py-h11

.include <bsd.port.mk>
