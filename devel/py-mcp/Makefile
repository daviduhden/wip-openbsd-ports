COMMENT =	model context protocol SDK

MODPY_DISTV =	2.3.0
DISTNAME =	mcp-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME}

CATEGORIES =	devel

HOMEPAGE =	https://modelcontextprotocol.io/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python

MODPY_PI =	Yes
MODPY_PYBUILD =	hatchling

BUILD_DEPENDS =	devel/py-uv-dynamic-versioning

TEST_DEPENDS =	devel/py-dirty-equals \
		devel/py-inline-snapshot \
		devel/py-test-xdist \
		devel/py-typer \
		net/py-websockets

RUN_DEPENDS =	devel/py-jsonschema>=4.20.0 \
		devel/py-mcp-types=2.3.0 \
		devel/py-opentelemetry-api>=1.28.0 \
		devel/py-pydantic>=2.12.0 \
		devel/py-typing-extensions>=4.13.0 \
		devel/py-typing-inspection>=0.4.1 \
		net/py-anyio>=4.10 \
		www/py-httpx2>=2.10.0 \
		www/py-jwt>=2.10.1 \
		www/py-python-multipart>=0.0.9 \
		www/py-sse-starlette>=3.0.0 \
		www/py-starlette>=0.48.0 \
		www/py-uvicorn>=0.31.1

MAKE_ENV +=	UV_DYNAMIC_VERSIONING_BYPASS=2.3.0

# The installed mcp entry point imports its CLI dependencies.
RUN_DEPENDS +=	devel/py-typer>=0.16.0 sysutils/py-dotenv>=1.0.0

TEST_DEPENDS += devel/py-blockbuster
# Tracing tests require the unported logfire and OpenTelemetry SDK.
MODPY_PYTEST_ARGS += --ignore=tests/shared/test_otel.py \
	--ignore=tests/docs_src/test_opentelemetry.py \
	--ignore=tests/docs --ignore=tests/examples --ignore=tests/test_examples.py

.include <bsd.port.mk>
