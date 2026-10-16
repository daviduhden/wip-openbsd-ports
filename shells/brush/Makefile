COMMENT =		Bourne-compatible shell written in Rust

V =			0.4.0
PTYPROCESS_V =		0.5.0
DISTNAME =		brush-${V}
GH_ACCOUNT =		reubeno
GH_PROJECT =		brush
GH_TAGNAME =		brush-shell-v${V}
CATEGORIES =		shells

HOMEPAGE =		https://github.com/reubeno/brush/

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		${MODCARGO_WANTLIB} m

MODULES =		devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

# The compatibility suite compares brush against bash as the oracle.  There is
# no bash in the OpenBSD base system, so pull shells/bash in for the test run
# and point the harness (config.rs: --bash-path, env BASH_PATH) at it.  This
# only affects testing; the package itself does not provide bash.
TEST_DEPENDS =		shells/bash
MAKE_ENV +=		BASH_PATH=${LOCALBASE}/bin/bash

post-extract:
	mkdir -p ${MODCARGO_VENDOR_DIR}
	if [ ! -d ${MODCARGO_VENDOR_DIR}/ptyprocess-${PTYPROCESS_V} ]; then \
		tar -xzf ${DISTDIR}/cargo/ptyprocess-${PTYPROCESS_V}.tar.gz \
			-C ${MODCARGO_VENDOR_DIR}; \
		${LOCALBASE}/bin/cargo-generate-vendor \
			${DISTDIR}/cargo/ptyprocess-${PTYPROCESS_V}.tar.gz \
			${MODCARGO_VENDOR_DIR}/ptyprocess-${PTYPROCESS_V}; \
	fi
	patch -F 0 -d ${MODCARGO_VENDOR_DIR}/ptyprocess-${PTYPROCESS_V} -p0 \
		< ${FILESDIR}/patch-ptyprocess_openbsd

# brush-shell is the workspace's default member and the package upstream
# recommends installing; the "brush" facade crate only forwards the same
# default features (basic reedline minimal).  The experimental feature set,
# which would embed uutils coreutils builtins, stays disabled.
MODCARGO_INSTALL_TARGET_PATHS =	brush-shell

# The shell is installed as ${PREFIX}/bin/brush only.  It is not installed as
# a bash(1) replacement, so the package carries no bin/bash, no @conflict and
# no shells/bash @pkgpath.

.include "crates.inc"

.include <bsd.port.mk>
