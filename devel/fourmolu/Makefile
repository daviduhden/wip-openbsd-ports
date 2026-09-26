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

CABAL_INC_HOME ?=	${WRKDIR}/.cabal-inc-home

# Print the MODCABAL_MANIFEST with the devel/cabal module's cabal-bundler:
#	cabal-bundler --openbsd fourmolu-0.20.1.0
cabal-inc:
	${INSTALL_DATA_DIR} ${CABAL_INC_HOME}
	${INSTALL_DATA_DIR} ${CABAL_INC_HOME}/.cabal
	env HOME=${CABAL_INC_HOME} CABAL_DIR=${CABAL_INC_HOME}/.cabal \
		LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal update
	if [ ! -f ${CABAL_INC_HOME}/.cabal/config ] && \
		[ -f ${CABAL_INC_HOME}/.config/cabal/config ]; then \
		cp ${CABAL_INC_HOME}/.config/cabal/config \
			${CABAL_INC_HOME}/.cabal/config; \
	fi
	env HOME=${CABAL_INC_HOME} CABAL_DIR=${CABAL_INC_HOME}/.cabal \
		LC_ALL=en_US.UTF-8 \
		${LOCALBASE}/bin/cabal-bundler --openbsd \
			${MODCABAL_STEM}-${MODCABAL_VERSION}

.include "cabal.inc"

.include <bsd.port.mk>
