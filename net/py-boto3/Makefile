COMMENT=		AWS SDK for Python

MODPY_DISTV =	1.43.111
DISTNAME =	boto3-${MODPY_DISTV}
PKGNAME=		py-${DISTNAME}

CATEGORIES=		net devel

HOMEPAGE=		https://github.com/boto/boto3

MAINTAINER=		Antoine Jacoutot <ajacoutot@openbsd.org>

# Apache 2.0
PERMIT_PACKAGE=		Yes

MODULES=		lang/python

MODPY_PI=		Yes
MODPY_PYBUILD =	setuptools

RUN_DEPENDS =	devel/py-jmespath>=0.7.1,<2.0.0 \
		net/py-botocore>=1.43.111,<1.44.0 \
		net/py-s3transfer>=0.19.0,<0.20.0

# No tests in the PyPI sdist.
NO_TEST =	Yes

.include <bsd.port.mk>
