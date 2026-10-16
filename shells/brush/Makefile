COMMENT =		Bourne-compatible shell written in Rust

V =			0.4.0
# zhiburt/ptyprocess has no OpenBSD support yet: it has no ptsname_r and has to
# call TIOCSCTTY on the pty slave, like FreeBSD and macOS.  Fetch the crate
# source with DIST_TUPLE, pinned to the 0.5.0 release commit, and consume it as
# a path dependency (patches/patch-Cargo_toml), so the OpenBSD fix in
# patches/patch-ptyprocess_src_lib_rs applies to a fixed, checksummed tree.
PTYPROCESS_COMMIT =	fe9e796035fc63c99136b706aa86354fab73d4bc
DISTNAME =		brush-${V}
GH_ACCOUNT =		reubeno
GH_PROJECT =		brush
GH_TAGNAME =		brush-shell-v${V}

DIST_TUPLE +=		github zhiburt ptyprocess ${PTYPROCESS_COMMIT} ptyprocess
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
