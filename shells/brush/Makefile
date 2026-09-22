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
# only affects testing; the built package still conflicts with shells/bash.
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

# bash(1) is installed as an alias so that ports depending on shells/bash
# work without source changes; pkg/PLIST declares @conflict/@pkgpath for
# shells/bash.  The shell is still available under its own name as well.
post-install:
	cd ${PREFIX}/bin && ln -sf brush bash

.include "crates.inc"

.include <bsd.port.mk>
