# Updating These Ports on OpenBSD

This document describes how to update a port that uses one of the
dependency-tracking port modules:

| Module | Ports | Generated file |
| --- | --- | --- |
| `devel/cargo` | `editors/msedit`, `converters/py-html-to-markdown`, `devel/py-litellm`, `textproc/py-tiktoken`, `sysutils/uutils` | `crates.inc` |
| `lang/go` | `devel/checkmake`, `devel/crush`, `devel/github-cli`, `devel/shfmt`, `net/xd-torrent` | `modules.inc` |
| `devel/cabal` | `net/simplexmq`, `net/simplex-chat` | `cabal.inc` |

The generated file lists every dependency the build is allowed to use.
It is derived from upstream metadata, never edited by hand, and always
committed together with `distinfo`.

Regenerating the file requires network access. The regular build must
stay offline and must reproduce the build from `distinfo` alone.

## Common Steps

1. Copy the port into the ports tree if it is not there yet:

   ```sh
   doas ./fetch-ports.ksh --copy-only /usr/ports category/port
   ```

2. Bump the version variables in the `Makefile`. Do not touch the
   generated dependency file in this step.
3. Regenerate the dependency file with the module target described
   below. The per-module section shows where `make makesum` sits in
   the sequence.
4. Make sure `distinfo` covers every new file. The generated file and
   `distinfo` must always change together.
5. Refresh the patches under `patches/` and, for the cabal ports, the
   dependency patches under `files/`. Keep the repository convention:
   one target file per patch, an `Index:` header and an
   `SPDX-License-Identifier:` line.
6. Run the full validation workflow:

   ```sh
   make clean=all
   make extract
   make patch
   make configure
   make build
   make fake
   make update-plist
   make port-lib-depends-check
   make package
   ```

7. Run the test suite where the port provides one (`make do-test`) and
   smoke-test the installed binaries.
8. Keep this repository in sync with what was tested: it is the source
   that `fetch-ports.ksh` installs, and `Makefile`, `distinfo`, the
   generated file, patches and `pkg/PLIST` must match the ports tree.

A `make clean` between regeneration and build avoids stale work
directories.

## Cargo Ports

Example: `editors/msedit`.

`crates.inc` records every crate in `MODCARGO_CRATES`. Bump
`GH_TAGNAME`, `PKGNAME` and any version variables derived from them in
the `Makefile` first.

Regenerate the crate list:

```sh
cd /usr/ports/editors/msedit
make clean=all
make extract
make patch
make makesum
make modcargo-gen-crates
make modcargo-gen-crates > /tmp/crates.inc
cp /tmp/crates.inc crates.inc
make clean=all
make extract
make patch
make makesum
make modcargo-gen-crates-licenses
make modcargo-gen-crates-licenses > /tmp/crates.inc
mv /tmp/crates.inc crates.inc
```

Notes:

- `make modcargo-gen-crates` reads upstream `Cargo.lock` and prints
  one `MODCARGO_CRATES` line per registry crate, without license
  comments. It needs the new upstream distfile, hence the first
  `make makesum`.
- `make modcargo-gen-crates-licenses` prints the same list annotated
  with the license found in each vendored `Cargo.toml`. It depends on
  the crates being downloaded, hence the second `make makesum`. Fix
  any `XXX missing license` entry by checking the crate tarball.
- Write to a temporary file first: redirecting into `crates.inc`
  truncates a file that `make` is reading.
- `make modcargo-metadata` regenerates the vendored crate metadata
  after manual crate changes; the wrapper target runs it as the build
  user.
- `sysutils/uutils` builds several uutils projects in one port, so its
  `crates.inc` is the union over all of their `Cargo.lock` files.
  Replace the `make modcargo-gen-crates` step with
  `make uutils-gen-crates`; the license pass and the rest of the
  sequence do not change. Also refresh the `*_V`/`*_COMMIT` variables
  for each project and the `DIST_TUPLE` entries that back the tar and
  awk git dependencies.
- If a dependency must stay at a version newer than what upstream
  pins, list it in `MODCARGO_CRATES_UPDATE`; the module runs
  `cargo update --package` for each entry during configure.

Before building, check:

- `WANTLIB`: cargo ports start from `${MODCARGO_WANTLIB}` and add the
  native libraries the crate build links against (for msedit, ICU).
- `LIB_DEPENDS`: native libraries discovered through pkg-config.
- `MODCARGO_FEATURES` and `MODCARGO_NO_DEFAULT_FEATURES` if upstream
  changed its default features.
- Custom targets: msedit sets `MODCARGO_INSTALL = No` and installs
  `${MODCARGO_TARGET_DIR}/release/edit` itself, and defines its own
  `do-test` target.

## Go Ports

Example: `net/xd-torrent`.

`modules.inc` records `MODGO_MODULES` and `MODGO_MODFILES`. Bump
`MODGO_VERSION` in the `Makefile` first. Some ports also carry the
version in `DISTNAME`, `PKGNAME` or `MODGO_LDFLAGS`.

Regenerate the module list:

```sh
cd /usr/ports/net/xd-torrent
make clean=all
make extract
make patch
make modgo-gen-modules
make modgo-gen-modules > /tmp/modules.inc
mv /tmp/modules.inc modules.inc
make makesum
```

Notes:

- To find the newest upstream version, run

  ```sh
  make MODGO_VERSION=latest modgo-gen-modules > modules.inc
  ```

  The helper resolves the latest version through `proxy.golang.org`
  and prints `MODGO_VERSION = ... # add this to Makefile, not
  modules.inc` on stderr. Put that value in the `Makefile` and rerun
  the target.
- `make makesum` downloads the module `.zip` and `.mod` files listed
  in `modules.inc` into `DISTDIR/go_modules` and updates `distinfo`.
- `MODGO_MODFILES` lists older `.mod` files that are needed to compute
  the build list but are not part of the final module graph. The
  helper fills both lists; do not merge them by hand.
- Update `MODGO_LDFLAGS` when the path of the upstream version
  variable changes. `devel/github-cli`, `devel/crush` and
  `devel/checkmake` inject version and build metadata this way.
- For ports with `DIST_TUPLE` replacements (`devel/github-cli` replaces
  `survey` with a patched fork), refresh the pinned commit and check
  whether the `pre-build` replace and its patch are still needed.
- Recheck `WANTLIB` (`c pthread` is typical), `RUN_DEPENDS` (for
  example `net/i2pd` for xd-torrent) and `post-install` hooks such as
  symlinks and generated manual pages.

## Cabal Ports

Examples: `net/simplexmq` and `net/simplex-chat`.

`cabal.inc` records `MODCABAL_MANIFEST`, the Hackage dependency set.
It is produced by a port-specific `cabal-inc` target that calls
`cabal-bundler --openbsd` and merges the result through
`files/cabal-deps-merge.pl`.

Bump the following before regenerating:

- `GH_TAGNAME`, `V` and `DISTNAME` for the upstream release.
- `MODCABAL_STEM` and `MODCABAL_VERSION` for the package version on
  Hackage. It can differ from the upstream release version.
- `MODCABAL_EXECUTABLES` if the executable set changed.
- The pinned dependency versions used by the project options and the
  patches: `NETWORK_V`, `HTTP2_V`, `TLS_V`, `UNIX_TIME_V`,
  `CRYPTOSTORE_V`, `ENTROPY_V`, and `WITHERABLE_V` for
  `net/simplex-chat`.
- The `DIST_TUPLE` commit hashes for the vendored GitHub dependencies.

Regenerate the manifest:

```sh
cd /usr/ports/net/simplexmq
make clean=all
make extract
make patch
make makesum
make cabal-inc
make clean=all
make extract
make patch
make makesum
```

Notes:

- The first `make makesum` records checksums for the new upstream and
  `DIST_TUPLE` snapshots; `cabal-inc` depends on `patch`, which needs
  them. The second one adds the Hackage tarballs listed in the new
  `cabal.inc` and drops stale entries.
- `make cabal-inc` runs `cabal update`, computes the executable and
  test build plans, and writes `cabal.inc` in the port directory. It
  requires network access, `devel/cabal-install`, `lang/ghc` and
  `cabal-bundler`.
- `CABAL_INC_HOME` keeps the temporary cabal home inside `WRKDIR`.
  `CABAL_INC_SKIP` and `CABAL_INC_EXTRA` control which packages are
  replaced by patched sources or forced to a fixed version.
- Dependency patches may be skipped during `cabal-inc` when their
  tarballs are not fetched yet; they are applied by the next clean
  `make patch`, which is part of the validation workflow.
- When a patched dependency moves to a new version, update the
  matching `*_V` variable and refresh the patch files that reference
  its path (`TLS_PATCHES`, `HTTP2_PATCHES`, the cryptostore, aeson,
  network, unix-time and entropy patches). The `find ... -name '*.hs'`
  loop in `post-patch` normalizes line endings before the dependency
  patches are applied.
- Keep the `cabal.project.local` stanzas, `allow-newer: *` and the
  `*_CABAL_*` option variables consistent; they are assembled in
  `post-patch`, `cabal-inc` and `do-test`.

These ports have deep dependency trees, so a clean build takes a long
time (`net/simplexmq` builds two servers and a library and is around
two hours on amd64 with four jobs). Run the test suite with:

```sh
make do-test
```

The test plan must have been produced by the last `cabal-inc` run; the
first run needs network access for test-only dependencies.

## Validation Checklist

- [ ] Version variables bumped in the `Makefile`.
- [ ] Generated file regenerated with the module target.
- [ ] `make makesum` run in the order the module section describes.
- [ ] `make patch` applies cleanly, stale patches dropped.
- [ ] Patches follow the repository format (one target file, `Index:`
      header, SPDX identifier).
- [ ] `make update-plist` run if the installed file set changed.
- [ ] `make port-lib-depends-check` passes.
- [ ] `make package` succeeds.
- [ ] `make do-test` passes where available.
- [ ] Package installs and the main binaries start.
