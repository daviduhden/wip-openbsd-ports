COMMENT =	alternative implementation of GNU sed

GH_PROJECT =	sed
GH_TAGNAME =	0.1.1

WANTLIB += ${MODCARGO_WANTLIB}

post-install:
	cd ${PREFIX}/bin && for program in *; do \
		mv $$program uu-$$program; \
	done

.include "crates.inc"

.include <bsd.port.mk>
