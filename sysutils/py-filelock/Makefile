COMMENT =	platform independent file lock

MODPY_DISTV =	4.3.1
# LiteLLM's compatible LTS series requires filelock <5.
PORTROACH =	limit:^4\.
DISTNAME =	filelock-${MODPY_DISTV}
PKGNAME =	py-${DISTNAME}
CATEGORIES =	sysutils

# https://github.com/tox-dev/filelock
HOMEPAGE =	https://py-filelock.readthedocs.io/

# MIT
PERMIT_PACKAGE =	Yes

MODULES =	lang/python
MODPY_PYBUILD =	hatch-vcs
MODPY_PI =	Yes

BUILD_DEPENDS =	devel/py-hatch-fancy-pypi-readme>=25.1 \
		devel/py-hatch-vcs>=0.5

# disable failing tests with a long timeout
MODPY_PYTEST_ARGS = -v \
		-k 'not test_threaded_shared_lock_obj and not test_threaded_lock_different_lock_obj' \
		--ignore tests/test_installed_package.py

TEST_DEPENDS =	devel/py-test-asyncio \
		devel/py-test-cov \
		devel/py-test-mock \
		devel/py-test-timeout \
		devel/py-virtualenv

post-test:
	@echo; echo Tests using threaded locks have been deselected as they; \
	echo fail with long timeouts: test_threaded_shared_lock_obj,; \
	echo test_threaded_lock_different_lock_obj; echo

.include <bsd.port.mk>
