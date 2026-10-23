COMMENT =	A minimal low-level HTTP client.

MODPY_DISTV =	2.16.0
DISTNAME =	httpcore2-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	www

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	hatchling

RUN_DEPENDS =	security/py-truststore>=0.10 \
		www/py-h11>=0.16

BUILD_DEPENDS +=	devel/py-uv-dynamic-versioning>=0.14.1 \
		devel/py-hatch-fancy-pypi-readme

MAKE_ENV +=	UV_DYNAMIC_VERSIONING_BYPASS=2.16.0

# No tests in the PyPI sdist.
NO_TEST =	Yes

.include <bsd.port.mk>
