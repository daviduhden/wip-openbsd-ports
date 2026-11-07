COMMENT =	High-performance HTML to Markdown converter

MODPY_DISTV =	3.21.2
GH_ACCOUNT =	xberg-io
GH_PROJECT =	html-to-markdown
GH_TAGNAME =	v${MODPY_DISTV}
PKGNAME =	py-${GH_PROJECT}-${MODPY_DISTV}

CATEGORIES =	converters

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PYBUILD =	maturin

# The release repository includes the workspace lock omitted from PyPI.
WRKSRC =	${WRKDIST}/packages/python
MODCARGO_CARGOTOML =	${WRKDIST}/crates/html-to-markdown-py/Cargo.toml
MODCARGO_CARGOLOCK =	${WRKDIST}/Cargo.lock
WANTLIB +=	${MODCARGO_WANTLIB:Npthread}
MAKE_JOBS =	1
MODCARGO_ENV +=	CARGO_PROFILE_RELEASE_LTO=off

.include "crates.inc"

# Run the synchronous visitor regressions against the installed wheel.
MODPY_TEST_DIR =	${WRKDIR}
MODPY_PYTEST_ARGS = -c /dev/null ${WRKSRC}/tests/test_visitor.py

# Let maturin read the Python package's pyproject.toml before resolving
# its Cargo manifest; --manifest-path would select workspace metadata.
do-build:
	${MODCARGO_CARGO_RUN} build --release --locked ${MODCARGO_BUILD_ARGS}

.include <bsd.port.mk>
