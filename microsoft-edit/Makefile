COMMENT = 	simple terminal text editor inspired in the MS‑DOS Editor

GH_ACCOUNT =	microsoft
GH_PROJECT =	edit
GH_TAGNAME =	1.2.1

CATEGORIES = 	editors
HOMEPAGE = 		https://github.com/microsoft/edit

# MIT
PERMIT_PACKAGE = Yes
ONLY_FOR_ARCHS = ${RUST_ARCHS}

WANTLIB += 		${MODCARGO_WANTLIB} ${COMPILER_LIBCXX}
LIB_DEPENDS = 	textproc/icu4c

COMPILER = 		base-clang ports-gcc
MODULES = 		devel/cargo

CONFIGURE_STYLE = cargo

.include "crates.inc"

.include <bsd.port.mk>
