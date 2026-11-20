COMMENT =	alternative implementation of GNU grep

GH_PROJECT =	grep
GH_TAGNAME =	0.2.0
REVISION =	0

# This Rust port uses getexecpath() for current_exe(), without a ps promise.
BUILD_DEPENDS +=	lang/rust>=1.99.1

LIB_DEPENDS =	textproc/oniguruma

WANTLIB += ${MODCARGO_WANTLIB} onig

post-install:
	env PREFIX=${PREFIX} sh ${FILESDIR}/prefix-binaries.sh

.include "crates.inc"

.include <bsd.port.mk>
