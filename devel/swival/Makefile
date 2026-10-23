COMMENT =		coding agent for AI models

MODPY_DISTV =		1.0.48
GH_ACCOUNT =		swival
GH_PROJECT =		swival
GH_TAGNAME =		${MODPY_DISTV}

CATEGORIES =		devel
HOMEPAGE =		https://swival.dev/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/python
MODPY_PYBUILD =		hatchling

BUILD_DEPENDS =		devel/py-hatchling>=1.32.4
RUN_DEPENDS =		converters/py-html-to-markdown>=3.18.1,<4 \
			devel/py-google-cloud-aiplatform>=2.5.0,<3 \
			devel/py-litellm>=1.105.1,<1.106 \
			devel/py-mcp>=2.3.0,<3 \
			devel/py-prompt_toolkit>=3.0.53 \
			devel/py-rich>=15.0.0 \
			net/py-boto3>=1.43.114 \
			security/py-fast-cipher>=0.3.0 \
			textproc/py-rank-bm25>=0.2.2 \
			textproc/py-tiktoken>=0.14.0 \
			www/py-httpx2>=2.13.1 \
			www/py-starlette>=1.8.0 \
			www/py-uvicorn>=0.54.0

MODPY_PYTEST_ARGS =	-m 'not stress'
TEST_ENV +=		LITELLM_LOCAL_MODEL_COST_MAP=True

# Optional metaskills need starlark-go, which requires Go's c-shared mode
# (not implemented on OpenBSD; golang/go#33896).

# The website builder shadows the Python build frontend.
post-extract:
	mv ${WRKSRC}/build.py ${WRKSRC}/build-website.py

.include <bsd.port.mk>
