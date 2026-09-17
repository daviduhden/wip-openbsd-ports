COMMENT =		coding agent for AI models

MODPY_DISTV =		1.0.44
DISTNAME =		swival-${MODPY_DISTV}
REVISION =		0

CATEGORIES =		devel

HOMEPAGE =		https://pypi.org/project/swival/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =		hatchling

# XXX may need porting: devel/py-google-cloud-aiplatform is required by
# upstream but is not available.  It would pull in the Google Cloud SDK
# stack and conflicts with protobuf/websockets versions in the tree.

RUN_DEPENDS =	converters/py-html-to-markdown>=3.12.3,<4 \
		devel/py-litellm>=1.100.1,<1.101 \
		devel/py-mcp>=2.2.0,<3 \
		devel/py-prompt_toolkit>=3.0.53 \
		devel/py-rich>=15.0.0 \
		net/py-boto3>=1.43.93 \
		security/py-fast-cipher>=0.2.2 \
		textproc/py-rank-bm25>=0.2.2 \
		textproc/py-tiktoken>=0.14.0 \
		www/py-httpx2>=2.12.0 \
		www/py-starlette>=1.6.0 \
		www/py-uvicorn>=0.52.4

.include <bsd.port.mk>
