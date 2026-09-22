COMMENT-main =		Rust implementations of the GNU core utilities and friends
COMMENT-coreutils =	Rust implementation of the GNU core utilities
COMMENT-findutils =	Rust implementation of the GNU find utilities
COMMENT-diffutils =	Rust implementation of the GNU diff utilities
COMMENT-grep =		Rust implementation of GNU grep
COMMENT-awk =		Rust implementation of awk
COMMENT-sed =		Rust implementation of sed
COMMENT-tar =		Rust implementation of tar

V =			0.12.0
DISTNAME =		coreutils-${V}

FINDUTILS_V =		0.10.0
DIFFUTILS_V =		0.5.0
GREP_V =		0.2.0
SED_V =			0.2.0
AWK_V =			0.1.0
TAR_V =			0.0.1

# uutils/awk and uutils/tar have not cut a release yet.  The revisions below
# are the ones this port was prepared against.
AWK_COMMIT =		a0b5a8c1705e12efa0912aade1f9d0a423a9badc
TAR_COMMIT =		95cc92d49fc304b3087542899b29b049fd1e3945

# uutils/tar depends on an unreleased uucore from the uutils/coreutils git
# tree.  Pin the revision recorded in tar's Cargo.lock and build it from that
# checkout with files/patch-tar_Cargo_toml.
UUCORE_COMMIT =		9f29502db083d57553c65ec3c8ed94a1e29fed21

MULTI_PACKAGES =	-main -coreutils -findutils -diffutils -grep -awk -sed -tar

PKGNAME-main =		uutils-${V}
PKGNAME-coreutils =	uutils-coreutils-${V}
PKGNAME-findutils =	uutils-findutils-${FINDUTILS_V}
PKGNAME-diffutils =	uutils-diffutils-${DIFFUTILS_V}
PKGNAME-grep =		uutils-grep-${GREP_V}
PKGNAME-awk =		uutils-awk-${AWK_V}
PKGNAME-sed =		uutils-sed-${SED_V}
PKGNAME-tar =		uutils-tar-${TAR_V}

CATEGORIES =		sysutils

HOMEPAGE =		https://uutils.github.io/

# MIT, except uutils/diffutils which is MIT OR Apache-2.0
PERMIT_PACKAGE =	Yes

# uutils/findutils and uutils/grep use Oniguruma through onig_sys, and
# uutils/tar uses zstd through zstd_sys.  The devel/cargo module removes the
# vendored copies and links the system libraries instead.
LIB_DEPENDS-findutils =	textproc/oniguruma
LIB_DEPENDS-grep =	textproc/oniguruma
LIB_DEPENDS-tar =	archivers/zstd

WANTLIB-main =
WANTLIB-coreutils =	${MODCARGO_WANTLIB} m
WANTLIB-findutils =	${MODCARGO_WANTLIB} onig
WANTLIB-diffutils =	${MODCARGO_WANTLIB}
WANTLIB-grep =		${MODCARGO_WANTLIB} onig
WANTLIB-awk =		${MODCARGO_WANTLIB} m
WANTLIB-sed =		${MODCARGO_WANTLIB}
WANTLIB-tar =		${MODCARGO_WANTLIB} zstd

# blake3 (uutils/coreutils) and minrx (uutils/awk) ship C sources that are
# compiled with the C compiler.
COMPILER =		base-clang ports-gcc
COMPILER_LANGS =	c

MODULES =		devel/cargo \
			lang/clang
CONFIGURE_STYLE =	cargo
SEPARATE_BUILD =	Yes

# uutils/awk's minrx-sys build script runs bindgen at build time.
MODCLANG_COMPILER_LINKS =	No
MODCARGO_ENV +=		LIBCLANG_PATH=${LOCALBASE}/llvm${MODCLANG_VERSION}/lib \
			LD_LIBRARY_PATH=${LOCALBASE}/llvm${MODCLANG_VERSION}/lib

# The devel/cargo module makes zstd-sys link the system libzstd without
# adding its directory to the search path.
MODCARGO_RUSTFLAGS +=	-L${LOCALBASE}/lib

# The coreutils release is the primary distfile; the remaining projects are
# pinned tarballs fetched from GitHub by DIST_TUPLE.
GH_ACCOUNT =		uutils
GH_PROJECT =		coreutils
GH_TAGNAME =		${V}

DIST_TUPLE +=		github uutils findutils ${FINDUTILS_V} ../findutils
DIST_TUPLE +=		github uutils diffutils v${DIFFUTILS_V} ../diffutils
DIST_TUPLE +=		github uutils grep ${GREP_V} ../grep
DIST_TUPLE +=		github uutils sed ${SED_V} ../sed
DIST_TUPLE +=		github uutils awk ${AWK_COMMIT} ../awk
DIST_TUPLE +=		github uutils tar ${TAR_COMMIT} ../tar
DIST_TUPLE +=		github Hans-Halverson indexmap-allocator-api \
			36852f985c01fb9f58f2d9e510655ca1dbb1f4d0 \
			../indexmap-allocator-api
DIST_TUPLE +=		github uutils coreutils ${UUCORE_COMMIT} ../coreutils-uucore

# gstdbuf(1) expects libstdbuf.so in the same place as sysutils/coreutils.
MAKE_ENV +=		LIBSTDBUF_DIR=${TRUEPREFIX}/libexec/coreutils

# The GNU-compatible names from sysutils/coreutils, installed as symlinks to
# the multicall binary, which dispatches on argv[0].  pkg/PLIST-coreutils
# declares @conflict/@pkgpath for sysutils/coreutils, so ports that use the
# GNU commands need no source changes, only their build dependency pointed at
# this package.
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

# The tar and awk sources use git dependencies that are not available from
# crates.io; point them at the checkouts fetched by DIST_TUPLE above.  The
# awk register leak check is disabled because the ports profile uses
# panic=unwind, whose cleanup paths instantiate Drop for LinearReg and make
# the const panic fire at compile time.
post-patch:
	patch -d ${WRKDIR}/tar -p0 < ${FILESDIR}/patch-tar_Cargo_toml
	patch -d ${WRKDIR}/awk -p0 \
		< ${FILESDIR}/patch-awk_interpreter_Cargo_toml
	patch -d ${WRKDIR}/awk -p0 \
		< ${FILESDIR}/patch-awk_interpreter_src_ir_lower_utils_rs
	# The findutils tests that depend on root privileges, on the filesystem
	# timestamp/birthtime resolution or on the system clock cannot pass in the
	# OpenBSD test environment; skip them like the coreutils ones.
	patch -d ${WRKDIR}/findutils -p0 \
		< ${FILESDIR}/patch-findutils_src_find_matchers_mod_rs
	patch -d ${WRKDIR}/findutils -p0 \
		< ${FILESDIR}/patch-findutils_src_find_matchers_time_rs
	patch -d ${WRKDIR}/findutils -p0 \
		< ${FILESDIR}/patch-findutils_src_find_mod_rs

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release \
		--no-default-features --features 'unix feat_external_libstdbuf'
	cd ${WRKDIR}/findutils && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release
	cd ${WRKDIR}/diffutils && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release
	cd ${WRKDIR}/grep && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release
	cd ${WRKDIR}/sed && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release
	cd ${WRKDIR}/awk && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release
	cd ${WRKDIR}/tar && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} build --release

do-install:
	${INSTALL_DATA_DIR} ${PREFIX}/bin
	# uutils/coreutils
	${INSTALL_DATA_DIR} ${PREFIX}/libexec/coreutils
	${INSTALL_DATA_DIR} ${PREFIX}/libexec/uutils
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/coreutils \
		${PREFIX}/libexec/uutils/coreutils
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/deps/libstdbuf.so \
		${PREFIX}/libexec/coreutils/libstdbuf.so
.for g in ${GNU_UTILS}
	ln -sf ../libexec/uutils/coreutils "${PREFIX}/bin/${g}"
.endfor
	# uutils/findutils
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/find ${PREFIX}/bin/gfind
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/locate ${PREFIX}/bin/glocate
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/updatedb ${PREFIX}/bin/gupdatedb
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/xargs ${PREFIX}/bin/gxargs
	# uutils/diffutils: a multicall binary supporting cmp and diff, exposed
	# under the names used by textproc/gdiff.
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/diffutils \
		${PREFIX}/libexec/uutils/diffutils
	ln -sf ../libexec/uutils/diffutils ${PREFIX}/bin/gcmp
	ln -sf ../libexec/uutils/diffutils ${PREFIX}/bin/gdiff
	# uutils/grep: egrep(1) and fgrep(1) are grep(1) with -E and -F.
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/grep ${PREFIX}/bin/ggrep
	printf '#!/bin/sh\nexec %s/bin/ggrep -E "$$@"\n' '${TRUEPREFIX}' \
		> ${PREFIX}/bin/gegrep
	printf '#!/bin/sh\nexec %s/bin/ggrep -F "$$@"\n' '${TRUEPREFIX}' \
		> ${PREFIX}/bin/gfgrep
	chmod ${BINMODE} ${PREFIX}/bin/gegrep ${PREFIX}/bin/gfgrep
	# uutils/awk, uutils/sed, uutils/tar
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/awk ${PREFIX}/bin/gawk
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/sed ${PREFIX}/bin/gsed
	${INSTALL_PROGRAM} ${MODCARGO_TARGET_DIR}/release/tarapp ${PREFIX}/bin/gtar

# The devel/cargo module's modcargo-gen-crates only reads a single Cargo.lock.
# This port builds several independent projects, so the generated crates.inc
# is the union over all of them.  files/crates-deps-merge.pl merges the
# registry entries of every lock file the way files/cabal-deps-merge.pl merges
# the cabal-bundler output for the cabal ports; run `make uutils-gen-crates`
# and then add licenses with the usual workflow (see BUILDING.md).  Keep the
# checkout and installed ports tree in sync when both are present.
uutils-gen-crates: extract
	perl ${FILESDIR}/crates-deps-merge.pl \
		--output ${.CURDIR}/crates.inc \
		--output /usr/ports/sysutils/uutils/crates.inc \
		--licenses ${.CURDIR}/crates.inc \
		${WRKDIST}/Cargo.lock \
		${WRKDIR}/findutils/Cargo.lock \
		${WRKDIR}/diffutils/Cargo.lock \
		${WRKDIR}/grep/Cargo.lock \
		${WRKDIR}/sed/Cargo.lock \
		${WRKDIR}/awk/Cargo.lock \
		${WRKDIR}/tar/Cargo.lock

# The devel/cargo test target runs with --release and debug assertions
# disabled, so uucore resolves its locale files relative to the test binary
# instead of the source tree.  Expose the in-tree locales under the release
# directory so the localization tests find them, then run that test target.
# The meta-package bundles several independent cargo workspaces, so run the
# tests of every packaged project, not only coreutils.
UUTILS_TEST_WORKSPACES =	findutils diffutils grep sed awk tar

do-test:
	mkdir -p ${MODCARGO_TARGET_DIR}/release/locales
	for d in ${WRKSRC}/src/uu/*/locales; do \
		u=$${d%/locales}; u=$${u##*/}; \
		ln -sfn $$d ${MODCARGO_TARGET_DIR}/release/locales/$$u; \
	done
	ln -sfn ${WRKSRC}/src/uucore/locales \
		${MODCARGO_TARGET_DIR}/release/locales/uucore
	${MODCARGO_TEST_TARGET}
.for _ws in ${UUTILS_TEST_WORKSPACES}
	cd ${WRKDIR}/${_ws} && ${SETENV} ${MAKE_ENV} ${MODCARGO_ENV} \
		${MODCARGO_CARGO_BIN} test --release
.endfor

RUN_DEPENDS-main =	${BASE_PKGPATH},-coreutils=${V} \
			${BASE_PKGPATH},-findutils=${FINDUTILS_V} \
			${BASE_PKGPATH},-diffutils=${DIFFUTILS_V} \
			${BASE_PKGPATH},-grep=${GREP_V} \
			${BASE_PKGPATH},-awk=${AWK_V} \
			${BASE_PKGPATH},-sed=${SED_V} \
			${BASE_PKGPATH},-tar=${TAR_V}

.include "crates.inc"

.include <bsd.port.mk>
