COMMENT =	Haskell source code formatter

MODULES =	devel/cabal
MODCABAL_STEM =	fourmolu
MODCABAL_VERSION =	0.20.1.0
MODCABAL_REVISION =	1
MODCABAL_EXECUTABLES =	fourmolu

CATEGORIES =	devel
HOMEPAGE =	https://github.com/fourmolu/fourmolu

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

WANTLIB +=	c ffi gmp iconv m pthread util

LIB_DEPENDS =	converters/libiconv \
		devel/gmp \
		devel/libffi

# Regenerate cabal.inc with the devel/cabal module's cabal-bundler:
#	cabal-bundler --openbsd fourmolu-0.20.1.0 > cabal.inc
cabal-inc:
	${LOCALBASE}/bin/cabal-bundler --openbsd \
		${MODCABAL_STEM}-${MODCABAL_VERSION} > ${.CURDIR}/cabal.inc

.include "cabal.inc"

.include <bsd.port.mk>
