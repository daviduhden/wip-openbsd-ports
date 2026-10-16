COMMENT =		library providing an API for accessing packages metadata

MODPY_DISTV =	8.9.0
DISTNAME =	importlib_metadata-${MODPY_DISTV}
PKGNAME =		py-${DISTNAME}
REVISION =       0

HOMEPAGE =		https://importlib-metadata.readthedocs.io/

CATEGORIES =		devel

MAINTAINER =		Renaud Allard <renaud@allard.it>

# Apache Software License
PERMIT_PACKAGE =	Yes

BUILD_DEPENDS =		misc/py-coherent.licensed

MODULES =		lang/python
MODPY_PI =		Yes
MODPY_PYBUILD =	setuptools

# disables tests needing pyfakefs, pytest-perf, jaraco.test (not in ports)
MODPY_PYTEST_ARGS =	--ignore exercises.py \
			--ignore tests/compat/py312.py \
			--ignore tests/fixtures.py \
			--ignore tests/test_api.py \
			--ignore tests/test_integration.py \
			--ignore tests/test_main.py \
			--ignore tests/test_zip.py
# ModuleNotFoundError: No module named 'test' (for "test.support")
TEST_DEPENDS =		${MODPY_RUN_DEPENDS},-tests

RUN_DEPENDS =	devel/py-zipp>=3.20

BUILD_DEPENDS +=	devel/py-setuptools_scm

# LiteLLM requires importlib-metadata <9.
PORTROACH =	limit:^8\.

.include <bsd.port.mk>
