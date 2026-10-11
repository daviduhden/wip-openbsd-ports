COMMENT =	fast BPE tokenizer for OpenAI models

MODPY_DISTV =	0.14.0
DISTNAME =	tiktoken-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME}

CATEGORIES =	textproc

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes

MODPY_PYBUILD =	setuptools-rust
MODPY_TEST_DIR =	${WRKINST}${MODPY_SITEPKG}

.include "crates.inc"
RUN_DEPENDS =	devel/py-regex \
		www/py-requests

WANTLIB +=	${MODCARGO_WANTLIB} m
MAKE_JOBS =	1
MODCARGO_ENV +=	CARGO_PROFILE_RELEASE_LTO=off

post-extract:
	${INSTALL_DATA} ${FILESDIR}/Cargo.lock ${WRKSRC}/Cargo.lock

.include <bsd.port.mk>
