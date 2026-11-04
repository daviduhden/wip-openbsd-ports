COMMENT =	Haskell source code formatter

MODULES =	devel/cabal
MODCABAL_STEM =	fourmolu
MODCABAL_VERSION =	0.21.0.0
MODCABAL_EXECUTABLES =	fourmolu

CATEGORIES =	devel
HOMEPAGE =	https://github.com/fourmolu/fourmolu

# BSD-3-Clause
PERMIT_PACKAGE =	Yes

WANTLIB +=	c ffi gmp iconv m pthread util

LIB_DEPENDS =	archivers/zstd \
		converters/libiconv \
		devel/gmp \
		devel/libffi

BUILD_DEPENDS =	devel/cabal-bundler \
		devel/cabal-install>=3.12.0.0 \
		lang/ghc>=9.8.3

# ghc and cabal-install also come from devel/cabal, with the same version
# constraints; cabal-bundler generates the dependency manifest from the build
# plan in the cabal-inc target.

CABAL_INC_HOME ?=	${WRKDIR}/.cabal-inc-home

# Generate the MODCABAL_MANIFEST with the devel/cabal module's cabal-bundler.
# The bundler repeats MODCABAL_STEM and MODCABAL_VERSION; drop those lines so
# this Makefile remains the single source of truth, then replace cabal.inc
# atomically after a successful run.
cabal-inc:
	env CABAL_INC_HOME=${CABAL_INC_HOME} LOCALBASE=${LOCALBASE} \
		WRKDIR=${WRKDIR} PORTDIR=${.CURDIR} \
		MODCABAL_STEM=${MODCABAL_STEM} \
		MODCABAL_VERSION=${MODCABAL_VERSION} \
		INSTALL_DATA_DIR="${INSTALL_DATA_DIR}" \
		sh ${FILESDIR}/cabal-inc.sh

.include "cabal.inc"

.include <bsd.port.mk>
