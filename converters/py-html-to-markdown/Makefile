COMMENT =		convert HTML to Markdown

MODPY_DISTV =		3.14.1
DISTNAME =		html_to_markdown-${MODPY_DISTV}
PKGNAME =		py-html-to-markdown-${MODPY_DISTV}

CATEGORIES =		converters

HOMEPAGE =		https://github.com/xberg-io/html-to-markdown

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =		maturin

MODCARGO_CARGOTOML =	${WRKSRC}/crates/html-to-markdown-py/Cargo.toml

.include "crates.inc"
.include <bsd.port.mk>
