ONLY_FOR_ARCHS =	${RUST_ARCHS}

COMMENT =	develop crates with pyo3, rust-cpython and cffi bindings

CATEGORIES =	devel

# MIT OR Apache-2.0
PERMIT_PACKAGE =	Yes

WANTLIB +=	${MODCARGO_WANTLIB} crypto m ssl

DISTNAME =	maturin-1.15.0
REVISION =       0
SITES =		https://files.pythonhosted.org/packages/source/m/maturin/

MODULES =	devel/cargo

CONFIGURE_STYLE = cargo

# disable rustls/ring for sparc64 support
MODCARGO_NO_DEFAULT_FEATURES = yes
MODCARGO_FEATURES =	cli-completion native-tls scaffolding upload

MODCARGO_CRATES_KEEP =	zstd-sys

.include "crates.inc"

# The PyPI sdist excludes tests, test-data and test-crates fixtures.
NO_TEST =	Yes

.include <bsd.port.mk>
