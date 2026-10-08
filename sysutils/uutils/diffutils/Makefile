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

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/diff ${PREFIX}/bin/uu-diff
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/cmp ${PREFIX}/bin/uu-cmp

.include "crates.inc"

.include <bsd.port.mk>
