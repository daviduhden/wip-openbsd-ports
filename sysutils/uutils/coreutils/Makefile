COMMENT =	alternative implementation of GNU coreutils

GH_PROJECT =	coreutils
GH_TAGNAME =	0.12.0

WANTLIB += ${MODCARGO_WANTLIB} m

post-install:
	cd ${PREFIX}/bin && for program in *; do \
		mv $$program uu-$$program; \
	done

.include "crates.inc"

.include <bsd.port.mk>
