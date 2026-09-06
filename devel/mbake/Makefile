COMMENT =		formatter and linter for GNU Makefiles

MODPY_DISTV =		1.4.6
GH_ACCOUNT =		EbodShojaei
GH_PROJECT =		bake
GH_TAGNAME =		v${MODPY_DISTV}
PKGNAME =		mbake-${MODPY_DISTV}
CATEGORIES =		devel

# MIT
PERMIT_PACKAGE =	Yes

MODULES =		lang/python
MODPY_PYBUILD =		hatchling

RUN_DEPENDS =		devel/gmake \
			devel/py-rich \
			devel/py-typer

PORTHOME =		${WRKDIR}

.include <bsd.port.mk>
