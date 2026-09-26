COMMENT =	Python bindings for the RIPE Atlas API

MODPY_DISTV =	2.3.0
GH_ACCOUNT =	RIPE-NCC
GH_PROJECT =	ripe-atlas-cousteau
GH_TAGNAME =	v${MODPY_DISTV}

PKGNAME =	py-ripe.atlas.cousteau-${MODPY_DISTV}

CATEGORIES =	net

# GPLv3
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-dateutil \
		devel/py-typing-extensions \
		net/py-websocket-client \
		www/py-requests

.include <bsd.port.mk>
