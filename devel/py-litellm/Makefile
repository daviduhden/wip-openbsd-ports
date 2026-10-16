COMMENT =	uniform API for multiple LLM providers

MODPY_DISTV =	1.105.1
DISTNAME =	litellm-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME}

CATEGORIES =	devel

HOMEPAGE =	https://litellm.ai/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python

MODPY_PI =	Yes
MODPY_PYBUILD =	maturin

TEST_DEPENDS =	www/py-fastapi

RUN_DEPENDS =	devel/py-click>=8.0.0,<9.0 \
		devel/py-fastuuid>=0.14.0,<1.0 \
		devel/py-huggingface-hub>=0.34.0,<2.0 \
		devel/py-importlib-metadata>=8.0.0,<9.0 \
		devel/py-jsonschema>=4.0.0,<5.0 \
		devel/py-openai>=2.20.0,<3.0.0 \
		devel/py-pydantic>=2.12.0,<3.0.0 \
		devel/py-pydantic-settings>=2.14.1,<3.0 \
		net/py-boto3>=1.43.1,<2.0 \
		sysutils/py-dotenv>=1.0.0,<2.0 \
		sysutils/py-filelock>=3.16.1,<4.0 \
		sysutils/py-packaging>=24.0 \
		textproc/py-tiktoken>=0.12.0,<1.0 \
		textproc/py-tokenizers>=0.21.0,<1.0 \
		textproc/py-yaml>=6.0.3,<7.0 \
		www/py-aiohttp>=3.14.2,<4.0 \
		www/py-httpx>=0.28.0,<1.0 \
		www/py-h2 \
		www/py-jinja2>=3.1.6,<4.0

MODCARGO_CARGOTOML =	${WRKSRC}/litellm-rust/crates/python-bridge/Cargo.toml
MODCARGO_CARGOLOCK =	${WRKSRC}/litellm-rust/Cargo.lock
MODCARGO_CRATES_KEEP =	libsqlite3-sys

BUILD_DEPENDS +=	devel/cmake/core devel/maturin=1.15.0
LIB_DEPENDS =	textproc/oniguruma
WANTLIB +=	${MODCARGO_WANTLIB} m onig

MODULES +=	lang/clang
MODCARGO_ENV +=	LIBCLANG_PATH=${LOCALBASE}/llvm${MODCLANG_VERSION}/lib \
		LD_LIBRARY_PATH=${LOCALBASE}/llvm${MODCLANG_VERSION}/lib \
		RUSTONIG_SYSTEM_LIBONIG=1 \
		CARGO_PROFILE_RELEASE_LTO=off
MAKE_JOBS =	1

# AWS-LC has readable constants in .text on amd64.
.if ${MACHINE_ARCH} == "amd64"
USE_NOEXECONLY =	Yes
.endif

.include "crates.inc"

# The PyPI sdist does not include the upstream test suite.
NO_TEST =	Yes

.include <bsd.port.mk>
