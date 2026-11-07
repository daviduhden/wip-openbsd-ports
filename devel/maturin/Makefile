ONLY_FOR_ARCHS =	${RUST_ARCHS}

COMMENT =	develop crates with pyo3, rust-cpython and cffi bindings

CATEGORIES =	devel

# MIT OR Apache-2.0
PERMIT_PACKAGE =	Yes

WANTLIB +=	${MODCARGO_WANTLIB} crypto m ssl

DISTNAME =	maturin-1.16.0
REVISION =	2
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

# Preserve strict upstream version checks; recognize base LibreSSL 4.4
# in the port patch instead of the module's unknown-version fallback.
MODCARGO_CRATES_KEEP +=	openssl-sys
MODCARGO_ENV +=		OPENSSL_NO_VENDOR=1 \
			OPENSSL_INCLUDE_DIR=/usr/include \
			OPENSSL_LIB_DIR=/usr/lib

.include <bsd.port.mk>
