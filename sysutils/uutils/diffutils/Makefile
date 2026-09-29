COMMENT =	alternative implementation of GNU diffutils

V =		0.5.0
PKGNAME =	uutils-diffutils-$V

WANTLIB += ${MODCARGO_WANTLIB}

GH_PROJECT =	diffutils
GH_TAGNAME =	v$V

post-install:
	cd ${PREFIX}/bin && for program in *; do \
		mv $$program uu-$$program; \
	done

.include "crates.inc"

.include <bsd.port.mk>
