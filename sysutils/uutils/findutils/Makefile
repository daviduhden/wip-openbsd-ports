COMMENT =	alternative implementation of GNU findutils

GH_PROJECT =	findutils
GH_TAGNAME =	0.10.0

LIB_DEPENDS =	textproc/oniguruma

WANTLIB += ${MODCARGO_WANTLIB} onig

post-install:
	cd ${PREFIX}/bin && for program in *; do \
		mv $$program uu-$$program; \
	done

.include "crates.inc"

.include <bsd.port.mk>
