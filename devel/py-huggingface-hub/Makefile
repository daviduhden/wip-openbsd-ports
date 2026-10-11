COMMENT =	client library for models and datasets on Hugging Face

MODPY_DISTV =	1.33.0
DISTNAME =	huggingface_hub-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-click>=8.4.2,<9.0.0 \
		devel/py-tqdm>=4.42.1 \
		devel/py-typing-extensions>=4.1.0 \
		sysutils/py-filelock>=3.10.0 \
		sysutils/py-fsspec>=2023.5.0 \
		sysutils/py-packaging>=20.9 \
		textproc/py-yaml>=5.1 \
		www/py-httpx>=0.23.0,<1

.include <bsd.port.mk>
