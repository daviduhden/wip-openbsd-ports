COMMENT =	High-performance HTML to Markdown converter

MODPY_DISTV =	3.17.2
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
WANTLIB +=	${MODCARGO_WANTLIB} m
MAKE_JOBS =	1
MODCARGO_ENV +=	CARGO_PROFILE_RELEASE_LTO=off

.include "crates.inc"

# The sdist ships a registry-crate lock in a workspace member directory.
# Use the lock resolved for the actual Python extension workspace.
post-extract:
	${INSTALL_DATA} ${FILESDIR}/Cargo.lock ${WRKSRC}/Cargo.lock

.include <bsd.port.mk>
