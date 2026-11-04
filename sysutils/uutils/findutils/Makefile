COMMENT =	alternative implementation of GNU findutils

GH_PROJECT =	findutils
GH_TAGNAME =	0.10.0

LIB_DEPENDS =	textproc/oniguruma

WANTLIB += ${MODCARGO_WANTLIB} onig

post-install:
	env PREFIX=${PREFIX} sh ${FILESDIR}/prefix-binaries.sh

.include "crates.inc"

.include <bsd.port.mk>
