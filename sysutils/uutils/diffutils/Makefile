COMMENT =	alternative implementation of GNU diffutils

V =		0.5.0
PKGNAME =	uutils-diffutils-$V

WANTLIB += ${MODCARGO_WANTLIB}

GH_PROJECT =	diffutils
GH_TAGNAME =	v$V

# Build diff and cmp as separate executables instead of the multicall
# diffutils binary.  patch-src_main_rs makes the argv[0] dispatch accept
# the uu- prefixed names used by the other packages.
MODCARGO_INSTALL =	No

# The binaries compile the same unit tests as the library.
MODCARGO_TEST_ARGS =	--lib --test integration

# The permutation tests share temporary files.
MODCARGO_LIBTEST_ARGS =	--test-threads=1
TEST_DEPENDS =		devel/gpatch

pre-test:
	ln -fs ${LOCALBASE}/bin/gpatch ${WRKDIR}/bin/patch

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/diff ${PREFIX}/bin/uu-diff
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/cmp ${PREFIX}/bin/uu-cmp

.include "crates.inc"

.include <bsd.port.mk>
