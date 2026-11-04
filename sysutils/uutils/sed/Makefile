COMMENT =	alternative implementation of GNU sed

GH_PROJECT =	sed
GH_TAGNAME =	0.3.0

WANTLIB += ${MODCARGO_WANTLIB}

post-install:
	env PREFIX=${PREFIX} sh ${FILESDIR}/prefix-binaries.sh

.include "crates.inc"

.include <bsd.port.mk>
