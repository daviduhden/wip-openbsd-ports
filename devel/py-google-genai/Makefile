COMMENT =	GenAI Python SDK

MODPY_DISTV =	2.29.0
DISTNAME =	google_genai-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-pydantic>=2.12.5,<3.0.0 \
		devel/py-sniffio \
		devel/py-tenacity>=8.2.3,<9.2.0 \
		devel/py-typing-extensions>=4.14.0,<5.0.0 \
		net/py-anyio>=4.8.0,<5.0.0 \
		net/py-websockets>=13.0.0,<17.0 \
		security/py-google-auth>=2.56.0,<3.0.0 \
		sysutils/py-distro>=1.7.0,<2 \
		www/py-httpx>=0.28.1,<1.0.0 \
		www/py-requests>=2.28.1,<3.0.0

BUILD_DEPENDS +=	sysutils/py-packaging>=24.2

.include <bsd.port.mk>
