COMMENT =	High-performance HTML to Markdown converter

MODPY_DISTV =	3.18.1
DISTNAME =	html_to_markdown-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	converters

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	maturin

MODCARGO_CARGOTOML =	${WRKSRC}/crates/html-to-markdown-py/Cargo.toml
MODCARGO_CARGOLOCK =	${WRKSRC}/Cargo.lock
WANTLIB +=	${MODCARGO_WANTLIB:Npthread}
MAKE_JOBS =	1
MODCARGO_ENV +=	CARGO_PROFILE_RELEASE_LTO=off

.include "crates.inc"

# No Python tests in the PyPI sdist.
NO_TEST =	Yes

.include <bsd.port.mk>
