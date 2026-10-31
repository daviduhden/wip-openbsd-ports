# Updating These Ports on OpenBSD

This document describes how to update a port that uses one of the
dependency-tracking port modules. The generated include is part of the
port, not a fixed property of the module:

| Module | Generated file |
| --- | --- |
| `devel/cargo` | `crates.inc` |
| `lang/go` | `modules.inc` |
| `devel/cabal` | `cabal.inc` |

Find the actual users with `git ls-files '*/crates.inc' '*/modules.inc'
'*/cabal.inc'`; do not rely on a static port list in this document.

The generated file lists every dependency the build is allowed to use.
It is derived from upstream metadata, never edited by hand, and always
committed together with `distinfo`.

Regenerating the file requires network access. The regular build must
stay offline and must reproduce the build from `distinfo` alone.

## Common Steps

### Required source and official-port review

Before changing a port, establish its current local version, patches, README,
and other local behavior. Identify the newest stable upstream release from the
project's release source; do not infer it from a port version or select a
development snapshot unless that port intentionally tracks one. Then inspect
the same port in the current official OpenBSD ports tree (prefer `-current`)
and compare its `Makefile`, patches, README, and packaging changes with the
local overlay. Incorporate applicable maintainer fixes while preserving local
changes that remain necessary. Record the upstream version/source, official
version/source, local changes retained or retired, and any official changes
not adopted with a reason. The official port is a reviewed reference, not a
replacement directory.

Review and update the port `Makefile` and `README` after each update. Rebase
every retained patch against pristine sources for the selected upstream
version, one source target per patch, using `diff -u -p`, a relative `Index:`
line, conventional `.orig`/target headers, and a specific rationale above the
header. Every rationale line must be at most 72 columns. Remove obsolete or
empty patches only after confirming the upstream source or another retained
change provides their behavior. Check the patch style and applicability.

When the task or host defers framework-generated files, do not regenerate
`distinfo`, `pkg/PLIST*`, or any generated `*.inc` outside a matching OpenBSD
ports tree. List each stale/deferred file and the OpenBSD target/check required
to refresh it. A source update with these files pending is not package-ready;
state that build, package, and runtime checks remain outstanding unless they
were actually run on OpenBSD.

1. Copy the port into the ports tree if it is not there yet:

   ```sh
   doas ./fetch-ports.ksh --copy-only /usr/ports category/port
   ```

2. Bump the version variables in the `Makefile`. Do not touch the
   generated dependency file in this step.
3. For a changed upstream release, record and review the new inputs
   before extracting:

   ```sh
   make clean=all
   make makesum
   make checksum
   ```

   `make makesum` rewrites `distinfo`; `make checksum` verifies it. Do not
   use `makesum` to hide an unexplained mismatch.
4. Regenerate the dependency file with the module target described
   below. The per-module section shows where `make makesum` sits in
   the sequence.
5. Make sure `distinfo` covers every new file. The generated file and
   `distinfo` must always change together.
6. Refresh the patches under `patches/` and, for the cabal ports, the
   dependency patches under `files/`. Keep the repository convention:
   one target file per patch, `diff -u -p` output, an `Index:` header,
   and a comment above it wrapped to 72 columns. Add an SPDX identifier
   only when the licensing of the authored material is established.
7. Run the full validation workflow:

   ```sh
   make clean=all
   make checksum
   make extract
   make patch
   make configure
   make build
   make fake
   make update-plist
   make port-lib-depends-check
   make package
   ```

8. Run the test suite where the port provides one (`make test`, or the
   documented `make do-test` target) and smoke-test the installed
   binaries.
9. Keep this repository in sync with what was tested: it is the source
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
make makesum
make extract
make patch
make modcargo-gen-crates > /tmp/crates.inc
# Inspect /tmp/crates.inc, then install the candidate.
mv /tmp/crates.inc crates.inc
make clean=all
make makesum
make extract
make patch
make configure
make modcargo-gen-crates-licenses > /tmp/crates.inc
# Inspect licenses and versions, then install the candidate.
mv /tmp/crates.inc crates.inc
make clean=all
```

Notes:

- `make modcargo-gen-crates` reads upstream `Cargo.lock` and prints
  one `MODCARGO_CRATES` line per registry crate, without license
  comments. It needs the new upstream distfile, hence the first
  `make makesum` and `make extract`.
- `make modcargo-gen-crates-licenses` prints the same list annotated
  with the license found in each vendored `Cargo.toml`. It depends on
  the crates being downloaded and configured, hence the second
  `make makesum` after the first candidate is installed. Fix any
  `XXX missing license` entry by checking the crate tarball; do not
  accept it as complete.
- Write to a temporary file first: redirecting into `crates.inc`
  truncates a file that `make` is reading. Check the generator's exit
  status and output before moving the file into place.
- `make modcargo-metadata` regenerates the vendored crate metadata
  after manual crate changes; the wrapper target runs it as the build
  user.
- `sysutils/uutils` is a group of subports, each building one uutils
  project from a single `Cargo.lock`, so the `make modcargo-gen-crates`
  sequence above applies inside each subport directory.  Also refresh
  the pinned revision in the subport `Makefile`: `GH_TAGNAME` for the
  released projects, and `AWK_COMMIT`/`INDEXMAP_COMMIT` or
  `TAR_COMMIT`/`UUCORE_COMMIT` plus the matching `DIST_TUPLE` entries
  for the unreleased ones.
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

Several Charm ports publish under the `charm.land` namespace with a
major-version suffix. Set `MODGO_MODNAME` to the full module path
(`charm.land/gum/v2`, `charm.land/glow/v3`) and keep `DISTNAME` on the
upstream project name; `lang/go` derives the proxy URL and the extracted
directory from `MODGO_MODNAME`.

Regenerate the module list:

```sh
cd /usr/ports/net/xd-torrent
make clean=all
make makesum
make extract
make patch
make modgo-gen-modules > /tmp/modules.inc
# Inspect /tmp/modules.inc, then install the candidate.
mv /tmp/modules.inc modules.inc
make makesum
```

Notes:

- To find the newest upstream version, run

  ```sh
  make MODGO_VERSION=latest modgo-gen-modules > /tmp/modules.inc
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
  whether the `pre-build` replace is still needed.
- Recheck `WANTLIB` (`c pthread` is typical), `RUN_DEPENDS` (for
  example `net/i2pd` for xd-torrent) and `post-install` hooks such as
  symlinks and generated manual pages.

## Cabal Ports

Examples: `devel/fourmolu`, `net/simplexmq` and `net/simplex-chat`.

`cabal.inc` records `MODCABAL_MANIFEST`, the Hackage dependency set.
Each port has its own `cabal-inc` target. `net/simplexmq` and
`net/simplex-chat` merge executables and test plans through
`files/cabal-deps-merge.pl`; `devel/fourmolu` filters the bundler output
and replaces its `cabal.inc`. All three write the manifest themselves.

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
make makesum
make extract
make patch
make cabal-inc
make clean=all
make makesum
make extract
make patch
```

Notes:

- The first `make makesum` records checksums for the new upstream and
  `DIST_TUPLE` snapshots; `make patch` then prepares the source that
  `cabal-inc` inspects. The second one adds the Hackage tarballs listed
  in the new `cabal.inc` and drops stale entries.
- `make cabal-inc` runs `cabal update`, computes the executable and
  test build plans, and writes `cabal.inc` in the port directory. It
  requires network access, `devel/cabal-install`, `lang/ghc` and
  `cabal-bundler`.
- For `devel/fourmolu`, `cabal-inc` filters the bundler's duplicate
  `MODCABAL_STEM` and `MODCABAL_VERSION` lines and replaces `cabal.inc`
  itself. Inspect the result and run `make makesum`.
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
make test
```

The test plan must have been produced by the last `cabal-inc` run; the
first run needs network access for test-only dependencies.

## Validation Checklist

- [ ] Version variables bumped in the `Makefile`.
- [ ] Generated file regenerated with the module target.
- [ ] `make makesum` run in the order the module section describes and
      `make checksum` verified.
- [ ] `make patch` applies cleanly, stale patches dropped.
- [ ] Patches follow the repository format (one target file, `Index:`
      header, `diff -u -p` output, comment at most 72 columns, and an
      SPDX identifier only when established).
- [ ] `make update-plist` run if the installed file set changed.
- [ ] `make port-lib-depends-check` passes.
- [ ] `make package` succeeds.
- [ ] `make test` (or the documented `do-test` target) passes where
      available.
- [ ] Package installs and the main binaries start.
