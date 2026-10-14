COMMENT =	The next generation HTTP client.

MODPY_DISTV =	2.13.1
DISTNAME =	httpx2-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	www

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	hatchling

RUN_DEPENDS =	net/py-anyio>=4.10 \
		net/py-idna>=3.18 \
		security/py-truststore>=0.10 \
		www/py-httpcore2=2.13.1

BUILD_DEPENDS +=	devel/py-uv-dynamic-versioning>=0.14.1 \
		devel/py-hatch-fancy-pypi-readme

MAKE_ENV +=	UV_DYNAMIC_VERSIONING_BYPASS=2.13.1

# No tests in the PyPI sdist.
NO_TEST =	Yes

.include <bsd.port.mk>
