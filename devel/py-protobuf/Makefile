COMMENT =		Google data interchange format (protocol buffers)

MODPY_DISTV =	6.33.6

DISTNAME =	protobuf-${MODPY_DISTV}
PKGNAME =		py-protobuf-${MODPY_DISTV}
REVISION =       0

# C11
COMPILER =		base-clang ports-gcc
COMPILER_LANGS =		c

FIX_EXTRACT_PERMISSIONS = Yes

CATEGORIES =		devel

# BSD
PERMIT_PACKAGE =		Yes

MODULES =		lang/python

MODPY_PI =		Yes
MODPY_PYBUILD =	setuptools

# No tests in sources on PyPi
NO_TEST =		Yes

# Google Cloud AI Platform and grpcio-status require protobuf <7.
PORTROACH =	limit:^6\.

.include <bsd.port.mk>
