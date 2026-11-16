COMMENT =	next-generation HTTP client

MODPY_DISTV =	2.16.0
DISTNAME =	httpx2-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

REVISION =	2

CATEGORIES =	www

HOMEPAGE =	https://httpx2.pydantic.dev/

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	hatchling

RUN_DEPENDS =	devel/py-click>=8.4.2 \
		devel/py-rich>=10,<16 \
		net/py-anyio>=4.10 \
		net/py-idna>=3.18 \
		security/py-truststore>=0.10 \
		textproc/py-pygments>=2,<3 \
		www/py-h2>=3,<5 \
		www/py-httpcore2=2.16.0

BUILD_DEPENDS +=	devel/py-uv-dynamic-versioning>=0.14.1 \
		devel/py-hatch-fancy-pypi-readme

MAKE_ENV +=	UV_DYNAMIC_VERSIONING_BYPASS=2.16.0

# No tests in the PyPI sdist.
NO_TEST =	Yes

.include <bsd.port.mk>
