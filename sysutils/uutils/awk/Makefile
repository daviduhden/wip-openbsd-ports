COMMENT =	alternative implementation of awk

# awk has not cut a release yet; pin the revision this port was prepared
# against.  Its indexmap-allocator-api git dependency is fetched from the
# recorded commit and wired in by patches/patch-interpreter_Cargo_toml.
AWK_COMMIT =		a0b5a8c1705e12efa0912aade1f9d0a423a9badc
INDEXMAP_COMMIT =	36852f985c01fb9f58f2d9e510655ca1dbb1f4d0

# The package version is the one in awk's workspace; the distfile is the
# pinned commit archive.
V =		0.1.0
DISTNAME =	uutils-awk-${V}
PKGNAME =	uutils-awk-${V}

DIST_TUPLE +=	github uutils awk ${AWK_COMMIT} .
DIST_TUPLE +=	github Hans-Halverson indexmap-allocator-api \
		${INDEXMAP_COMMIT} ../indexmap-allocator-api

# uutils/awk's minrx-sys build script runs bindgen at build time, and its
# C sources are compiled with the C compiler.
COMPILER =		base-clang ports-gcc
COMPILER_LANGS =	c

MODULES =		devel/cargo \
			lang/clang
MODCLANG_COMPILER_LINKS =	No
MODCARGO_ENV +=		LIBCLANG_PATH=${LOCALBASE}/llvm${MODCLANG_VERSION}/lib \
			LD_LIBRARY_PATH=${LOCALBASE}/llvm${MODCLANG_VERSION}/lib

WANTLIB +=		${MODCARGO_WANTLIB} m

# The binary is installed under the uu- prefix used by the other packages.
MODCARGO_INSTALL =	No

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/awk \
		${PREFIX}/bin/uu-awk

.include "crates.inc"

.include <bsd.port.mk>
