COMMENT =	Model Context Protocol wire types

MODPY_DISTV =	2.3.0
DISTNAME =	mcp_types-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	hatchling

RUN_DEPENDS =	devel/py-pydantic>=2.12.0 \
		devel/py-typing-extensions>=4.13.0

BUILD_DEPENDS +=	devel/py-uv-dynamic-versioning

MAKE_ENV +=	UV_DYNAMIC_VERSIONING_BYPASS=2.3.0

.include <bsd.port.mk>
