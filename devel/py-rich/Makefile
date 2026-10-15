COMMENT =	Python library for rich text and beautiful formatting

MODPY_DISTV =	15.0.0
DISTNAME =	rich-${MODPY_DISTV}
PKGNAME =	py-rich-${MODPY_DISTV}
REVISION =       0

CATEGORIES =	devel

# MIT
PERMIT_PACKAGE =	Yes

HOMEPAGE =	https://github.com/Textualize/rich
# https://rich.readthedocs.io/
MODULES =	lang/python
MODPY_PI =	Yes

MODPY_PYBUILD =	poetry-core
NO_TEST =	Yes

RUN_DEPENDS =	textproc/py-markdown-it>=2.2.0 \
		textproc/py-pygments>=2.13.0,<3.0.0

.include <bsd.port.mk>
