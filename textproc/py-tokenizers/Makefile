COMMENT =	tokenizers with a focus on performance

MODPY_DISTV =	0.23.3
REVISION =       0
DISTNAME =	tokenizers-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME}

CATEGORIES =	textproc

# Apache 2.0
PERMIT_PACKAGE =	Yes

# C++11
COMPILER =	base-clang ports-gcc

MODCARGO_CARGOTOML = ${WRKSRC}/bindings/python/Cargo.toml

MODULES =	lang/python

MODPY_PI =	Yes
MODPY_PYBUILD =	maturin

LIB_DEPENDS =	textproc/oniguruma
WANTLIB +=	${COMPILER_LIBCXX} c m onig
RUN_DEPENDS =	devel/py-huggingface-hub>=0.16.4,<3.0

# Let Maturin read the Python metadata outside the Rust workspace.
do-build:
	${MODCARGO_CARGO_RUN} build --release ${MODCARGO_BUILD_ARGS}

.include "crates.inc"

# Documentation tutorials require datasets and large online corpora.
MODPY_TEST_DIR = ${WRKSRC}/bindings/python
MODPY_PYTEST_ARGS = tests -m 'not network' --ignore=tests/documentation
.include <bsd.port.mk>
