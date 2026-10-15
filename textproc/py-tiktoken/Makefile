COMMENT =	fast BPE tokenizer for OpenAI models

MODPY_DISTV =	0.14.0
DISTNAME =	tiktoken-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME}
REVISION =       0

CATEGORIES =	textproc

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/python

MODPY_PI =		Yes

MODPY_PYBUILD =	setuptools-rust

.include "crates.inc"
RUN_DEPENDS =	devel/py-regex \
		www/py-requests

WANTLIB +=	${MODCARGO_WANTLIB:Npthread}
MAKE_JOBS =	1
MODCARGO_ENV +=	CARGO_PROFILE_RELEASE_LTO=off

MODPY_PYTEST_ARGS =	tests

MODPY_TEST_LINK_SO = Yes
TEST_DEPENDS = devel/py-hypothesis
.include <bsd.port.mk>
