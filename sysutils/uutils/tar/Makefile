COMMENT =	alternative implementation of tar

# tar has not cut a release yet; pin the revision this port was prepared
# against.  Its unreleased uucore and uutests come from the coreutils
# checkout recorded in tar's Cargo.lock and wired in by
# patches/patch-Cargo_toml.
TAR_COMMIT =	95cc92d49fc304b3087542899b29b049fd1e3945
UUCORE_COMMIT =	9f29502db083d57553c65ec3c8ed94a1e29fed21

# The package version is the one in tar's manifest; the distfile is the
# pinned commit archive.
V =		0.0.1
DISTNAME =	uutils-tar-${V}
PKGNAME =	uutils-tar-${V}

DIST_TUPLE +=	github uutils tar ${TAR_COMMIT} .
DIST_TUPLE +=	github uutils coreutils ${UUCORE_COMMIT} ../coreutils-uucore

LIB_DEPENDS =	archivers/zstd

WANTLIB +=	${MODCARGO_WANTLIB} zstd

# The devel/cargo module makes zstd-sys link the system libzstd without
# adding its directory to the search path.
MODCARGO_RUSTFLAGS +=	-L${LOCALBASE}/lib

# The binary is named tarapp upstream; install it under the uu- prefix
# used by the other packages.
MODCARGO_INSTALL =	No

do-install:
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/tarapp \
		${PREFIX}/bin/uu-tar

.include "crates.inc"

.include <bsd.port.mk>
