COMMENT =		Bourne-compatible shell written in Rust

V =			0.4.0
DISTNAME =		brush-${V}
GH_ACCOUNT =		reubeno
GH_PROJECT =		brush
GH_TAGNAME =		brush-shell-v${V}
CATEGORIES =		shells

HOMEPAGE =		https://github.com/reubeno/brush/

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		${MODCARGO_WANTLIB}

MODULES =		devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

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
