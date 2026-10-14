COMMENT =	OpenTelemetry Python API

MODPY_DISTV =	1.45.1
DISTNAME =	opentelemetry_api-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME:S/_/-/}

CATEGORIES =	devel

# Apache-2.0
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PI =	Yes
MODPY_PYBUILD =	hatchling

RUN_DEPENDS =	devel/py-typing-extensions>=4.5.0

# These tests require opentelemetry.test, absent from the sdist.
MODPY_PYTEST_ARGS = --ignore=tests/logs/test_logger_provider.py \
	--ignore=tests/logs/test_proxy.py --ignore=tests/metrics/test_meter_provider.py \
	--ignore=tests/trace/test_globals.py --ignore=tests/trace/test_proxy.py \
	--ignore=tests/util/test_once.py
.include <bsd.port.mk>
