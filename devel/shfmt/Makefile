COMMENT =	shell parser, formatter, and interpreter

MODGO_MODNAME =	mvdan.cc/sh/v3
MODGO_VERSION =	v3.14.1

DISTNAME =	shfmt-${MODGO_VERSION}

CATEGORIES =	devel

HOMEPAGE =	https://github.com/mvdan/sh

# BSD-3
PERMIT_PACKAGE =	Yes

WANTLIB += c pthread

MODULES =		lang/go

# The module default tests only the root package, which has no Go files;
# run the whole upstream suite instead.
TEST_TARGET =	./...

BUILD_DEPENDS =	textproc/groff \
		textproc/scdoc

do-install:
	( cd ${WRKSRC} && scdoc < cmd/shfmt/shfmt.1.scd > \
		${PREFIX}/man/man1/shfmt.1 )
	${MODGO_INSTALL_TARGET}

.include "modules.inc"

.include <bsd.port.mk>
