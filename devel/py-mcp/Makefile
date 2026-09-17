COMMENT=	model context protocol SDK

MODPY_DISTV=	2.2.0
DISTNAME=	mcp-${MODPY_DISTV}
PKGNAME=	py-${DISTNAME}
REVISION=	0

CATEGORIES=	devel

HOMEPAGE=	https://modelcontextprotocol.io/

# MIT
PERMIT_PACKAGE=	Yes

MODULES=	lang/python

MODPY_PI=	Yes
MODPY_PYBUILD=	hatchling

BUILD_DEPENDS=	devel/py-uv-dynamic-versioning

RUN_DEPENDS =	devel/py-jsonschema>=4.20.0 \
		devel/py-mcp-types=2.2.0 \
		devel/py-opentelemetry-api>=1.28.0 \
		devel/py-pydantic>=2.12.0,<3.0.0 \
		devel/py-typing-extensions>=4.13.0 \
		devel/py-typing-inspection>=0.4.1 \
		net/py-anyio>=4.9 \
		www/py-httpx2>=2.5.0 \
		www/py-jwt>=2.10.1 \
		www/py-python-multipart>=0.0.9 \
		www/py-sse-starlette>=3.0.0 \
		www/py-starlette>=0.48.0 \
		www/py-uvicorn>=0.31.1

TEST_DEPENDS =	devel/py-dirty-equals \
		devel/py-inline-snapshot \
		devel/py-test-xdist \
		devel/py-typer \
		net/py-websockets

.include <bsd.port.mk>
