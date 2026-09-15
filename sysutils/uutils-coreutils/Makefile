COMMENT =		Rust implementation of the Unix core utilities

V =			0.11.0
DISTNAME =		coreutils-${V}
PKGNAME =		uutils-coreutils-${V}
CATEGORIES =		sysutils

HOMEPAGE =		https://github.com/uutils/coreutils/

# MIT
PERMIT_PACKAGE =	Yes

WANTLIB +=		${MODCARGO_WANTLIB} m onig

# blake3 ships C and assembly sources that are compiled with the C compiler.
COMPILER =		base-clang ports-gcc
COMPILER_LANGS =	c

MODULES =		devel/cargo
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

# expr(1) uses the system Oniguruma through the onig crate.
LIB_DEPENDS =		textproc/oniguruma

# "unix" selects the upstream feat_os_unix utility set.  Default features are
# disabled to match upstream's multicall build (GNUmakefile, MULTICALL=y):
# feat_os_unix already pulls in every utility, and feat_diagnostics is only
# used when developing.  feat_external_libstdbuf makes stdbuf(1) load the
# separately installed libstdbuf.so instead of writing an embedded copy to a
# temporary directory at run time.
MODCARGO_NO_DEFAULT_FEATURES =	Yes
MODCARGO_FEATURES =	unix feat_external_libstdbuf
MODCARGO_INSTALL =	No

# The GNU-compatible names from sysutils/coreutils are installed as symlinks
# to the multicall binary, which dispatches on argv[0]; pkg/PLIST declares
# @conflict/@pkgpath for sysutils/coreutils.  Ports that use the GNU
# commands therefore need no source changes, only their build dependency
# pointed at this package.  gstdbuf(1) expects libstdbuf.so in the same
# location as sysutils/coreutils, hence the libexec/coreutils path.
MAKE_ENV +=		LIBSTDBUF_DIR=${TRUEPREFIX}/libexec/coreutils

GNU_UTILS =		g[ gb2sum gbase32 gbase64 gbasename gbasenc \
			gcat gchgrp gchmod gchown gchroot gcksum \
			gcomm gcp gcsplit gcut gdate gdd \
			gdf gdir gdircolors gdirname gdu gecho \
			genv gexpand gexpr gfactor gfalse gfmt \
			gfold ggid ggod ggpr ggroups ghead \
			ghostid ginstall gjoin glink gln glogname \
			gls gmd5sum gmkdir gmkfifo gmknod gmktemp \
			gmv gnice gnl gnohup gnproc gnumfmt \
			gpaste gpathchk gpinky gprintenv gprintf gptx \
			gpwd greadlink grealpath grm grmdir gseq \
			gsha1sum gsha224sum gsha256sum gsha384sum gsha512sum gshred \
			gshuf gsleep gsort gsplit gstat gstdbuf \
			gstty gsum gsync gtac gtail gtee \
			gtest gtimeout gtouch gtr gtrue gtruncate \
			gtsort gtty guname gunexpand guniq gunlink \
			gusers gvdir gwc gwho gwhoami gyes

do-install:
	${INSTALL_DATA_DIR} ${PREFIX}/libexec/coreutils
	${INSTALL_DATA_DIR} ${PREFIX}/libexec/uutils
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/coreutils \
		${PREFIX}/libexec/uutils/coreutils
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/deps/libstdbuf.so \
		${PREFIX}/libexec/coreutils/libstdbuf.so
.for g in ${GNU_UTILS}
	ln -sf ../libexec/uutils/coreutils "${PREFIX}/bin/${g}"
.endfor

.include "crates.inc"

.include <bsd.port.mk>
