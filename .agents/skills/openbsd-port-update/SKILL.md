---
name: openbsd-port-update
description: Update an existing OpenBSD port to a new upstream release or revision, including versions, patches, generated manifests, checksums, PLIST, ABI, dependencies, and regression checks.
---

# Update an existing OpenBSD port

Use this skill for a new upstream release, a pinned commit change, or a
packaged revision that does not change the upstream source. For a new port use
[openbsd-port-create](../openbsd-port-create/SKILL.md); for a dependency-only
refresh use [openbsd-port-dependencies](../openbsd-port-dependencies/SKILL.md).
Do not use this skill to perform an unauthorized install or a global package
upgrade.

## Prerequisites

Read [UPDATE.md](../../../docs/UPDATE.md), [BUILDING.md](../../../docs/BUILDING.md),
and the port's Makefile, distinfo, generated includes, patches, PLIST, and
package files. Record the current version and `REVISION`, the exact upstream
tag or commit, the current work directory, and the installed-package baseline.
Work in a matching OpenBSD tree; a Linux host can inspect files but cannot
establish that the update builds or runs.

Determine every version carrier before editing: `V`, `GH_TAGNAME`, `DISTNAME`,
`PKGNAME`, `MODPY_DISTV`, `MODGO_VERSION`, `MODCABAL_VERSION`, `VERSION`, a
pinned `*_COMMIT`, `DIST_TUPLE` hashes, `MODGO_LDFLAGS`, or a version embedded
in `SUBST_VARS`. A port can use several at once.

## Procedure

1. Record the baseline:

   ```sh
   make show=PKGNAME
   make show=PKGNAMES
   make show=REVISION
   git status --short
   git diff --stat
   ```

   Note any uncommitted user changes and preserve them. Do not run `git reset`,
   `git clean`, or `make clean=all` over work you have not inspected.

2. Read upstream release notes and the full source diff for the new version.
   Identify removed or renamed binaries, configuration keys, data formats,
   services, licenses, and dependencies. Check for security fixes that make a
   local patch obsolete. When an official ports update exists, inspect its
   exact CVS/Git commit and compare the port files individually; use its
   generated metadata and patches as reviewed inputs, not as a blind directory
   replacement. Preserve local-only behavior and packaging changes unless the
   new source makes them obsolete.

3. Bump the version variables. If the upstream version changes, remove
   `REVISION` or set it to the conventional initial value; a new upstream
   version starts a new package revision. For a customized overlay with an
   official counterpart, compare the official effective `REVISION` and set
   the local value higher to prevent package-name collisions; an omitted
   official value is zero. If only packaging changes and the upstream version
   is unchanged, bump `REVISION` (add `REVISION = 0` when it was absent). Use
   `EPOCH` only when the version ordering genuinely moves backwards, not as a
   substitute for a correct version.

4. Fetch and review the new inputs before extraction:

   ```sh
   make clean=all
   make makesum
   make checksum
   make extract
   ```

   `makesum` rewrites `distinfo` and trusts what it downloaded. Inspect the
   diff, the archive names, and the upstream provenance. Never regenerate a
   checksum to conceal a mismatch or an unexpected redirect.

5. Regenerate any dependency manifest with the module's own procedure in
   [openbsd-port-dependencies](../openbsd-port-dependencies/SKILL.md). Write
   generator output to a temporary file, verify exit status and contents, then
   replace the tracked include. `cabal.inc` handling differs between
   `devel/fourmolu` (stdout) and the SimpleX ports (their target writes the
   file); read the recipe.

6. Rebase or remove every patch with
   [openbsd-port-patches](../openbsd-port-patches/SKILL.md). A patch that still
   applies may no longer be needed. Update `*_V` variables and dependency
   patch paths when a vendored dependency moves. A clean `make patch` from a
   fresh extraction is mandatory.

7. Update metadata that follows the source: `WANTLIB`, `LIB_DEPENDS`,
   `RUN_DEPENDS`, `TEST_DEPENDS`, `SHARED_LIBS`, `SUBST_VARS`, installed
   manuals, completions, plugins, and service files. Check the shared-library
   ABI:

   ```sh
   make check-shlib-syms
   ```

   This target needs the matching source tree. An empty result does not prove
   ABI compatibility; read the upstream diff and bump the major version when
   the exported interface changed.

8. Rebuild and repackage:

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

   Review `pkg/PLIST` after `update-plist`; pay attention to new or removed
   files, `@sample` paths, users, rc.d scripts, and `MULTI_PACKAGES` splits.
   A version bump alone does not justify flattening a subpackage.

9. Run the tests and a real smoke test. `make test` uses the framework's test
   setup; `make do-test` calls the port target directly and may skip dependency
   handling. For daemons, test initialization, start, restart, reload, and stop
   on an authorized host. For GUI ports, at least verify startup and shutdown.
   Record network access needed by the test suite.

10. Finish [openbsd-port-validation](../openbsd-port-validation/SKILL.md) and
    synchronize only the tested result with
    [openbsd-ports-sync](../openbsd-ports-sync/SKILL.md).

## Static analysis with explicitly deferred generated files

When the task explicitly defers `distinfo`, `pkg/PLIST*`, or generated dependency
includes such as `crates.inc`, `modules.inc`, or `cabal.inc`, do not regenerate
them. Still inspect upstream manifests and source metadata for changed inputs,
record which artifacts remain stale, and report that the update is not yet
package-ready until those files are regenerated and validated on a matching
OpenBSD ports tree. Static patch applicability can be checked against the exact
upstream source archive in a temporary directory with zero fuzz; regenerate
patches that require offsets or fuzz, and remove patches whose upstream change
makes them unnecessary.

For each deferred update, name every pending `distinfo`, `pkg/PLIST*`, or
generated `*.inc` file and its OpenBSD regeneration target in the handoff.
Never modify those files from a non-OpenBSD host for a task that defers them.
Review the port `Makefile` and `README` even while package metadata remains
pending. The required source comparison in [UPDATE.md](../../../docs/UPDATE.md)
records stable upstream and official `-current` versions, adopted or declined
official changes, and local behavior retained or retired.

### Port README placement

Use `pkg/README` for user-facing package notes and begin it with the
standard banner:

```text
+-----------------------------------------------------------------------
| Running ${PKGSTEM} on OpenBSD
+-----------------------------------------------------------------------
```

A top-level `README` is not the OpenBSD convention; keep maintainer-only
build notes in the change handoff or a review artifact, not in an
installed file.  Use the framework variables (`${LOCALBASE}`,
`${SYSCONFDIR}`, `${PKGSTEM}`) rather than hard-coded paths, and keep
service, security and first-run instructions concise.

### Local-only and header-only ports

Some overlay ports have no official `-current` counterpart.  Confirm that
absence from the official tree instead of assuming a local directory is new.
For a single-header port, compare the release tree with the installed file
set, compile one translation unit with the implementation macro enabled, and
keep `pkg/PLIST` unchanged when the header and license are still the only
installed files.

If `distinfo` cannot be regenerated with OpenBSD `make makesum`, derive the
SHA-256 and size from the exact release tarball, record the source URL and
method in the handoff, and require `make checksum` on OpenBSD before
packaging.  Do not carry an old checksum for a new tag.

### XERJ (`devel/xerj`)

`devel/xerj` pins a prerelease tag and builds only the `xerj-server`
package from the `engine/` Cargo workspace.  Before any update:

1. Re-check upstream tags, releases, the selected tag's commit and whether
   a stable release now exists.
2. Read `engine/Cargo.toml`, every workspace member reachable from
   `xerj-server`, and the complete `engine/Cargo.lock`.  Confirm which
   package still produces `xerj`.
3. Review added/removed crates, optional features, target-specific
   dependencies and build scripts.  Keep the neural/decide feature
   selection explicit and documented.
4. Re-audit OpenBSD cfg branches, libc/nix/rustix usage and Linux-only
   constants or syscalls.  `RLIMIT_AS` and the Linux errno accessor are
   known non-portable examples; do not add a patch until the exact call
   site is verified.
5. Check target-cpu, ISA and assembly requirements; never add
   `target-cpu=native` to a distributable package.
6. Keep ports patches separate from upstreamable fixes.  Rebase with
   `diff -u -p`, one target per `Index:`, and keep comment lines at most
   72 columns.
7. Re-check system-library decisions: SQLite uses the system library,
   zstd uses `archivers/zstd`, and the Rust `openssl` crate must not
   vendor OpenSSL (`OPENSSL_NO_VENDOR=1`).
8. Keep TLS, authentication and validation enabled by default.  Do not
   add a service or user until runtime permissions and pledge/unveil
   behavior have been tested.  Document feature losses, packaging
   decisions and pending OpenBSD checks in the port `README` and update
   report.
9. Enable tests package-scoped to `xerj-server` and give them a writable
   `HOME`.  The integration tests use loopback listeners and temporary
   directories.  Do not run workspace-wide tests until the
   `xerj-autoindex` test module's Linux-only `RLIMIT_AS` references are
   gated.
10. Do not generate `crates.inc`, `distinfo` or `pkg/PLIST` outside
    OpenBSD.  Record `make modcargo-gen-crates`, `make makesum`,
    `make update-plist` and `make port-lib-depends-check` as pending.
11. Use independent read-only subagents for architecture, Cargo graph,
    native dependencies, OpenBSD compatibility and security questions.
12. Report static inspection separately from `make build`, `make test` and
    runtime evidence.

### Codex CLI (`devel/codex`)

When subagents are available, delegate read-only reviews in parallel for the
upstream release, official `-current` port, local patch stack, Cargo/native
dependencies, and OpenBSD process/security behavior. Reconcile their evidence
before editing. Compare all three source states; use the official patch set as
a reviewed update, not a replacement for local behavior. Recheck daemon
lifecycle and package-manager ownership, V8 source/version and GN patches,
PTY/exec behavior, and every sandbox fail-closed guard. The security skill
defines supported sandbox claims; the dependency skill covers Cargo/V8 source
mapping. Review `pkg/README` even when it needs no edit. Never claim OpenBSD
sandboxing works unless a supported kernel-enforced backend is implemented
and tested. Outside OpenBSD, leave `distinfo`, `pkg/PLIST`, and `crates.inc`
to the framework and list each pending file.

### LibreSSL-native ports

For a port that deliberately links the base-system LibreSSL, such as
`lang/node`, compare the official port and the local patch stack as usual, but
also verify that the build still selects the supported legacy backend rather
than pretending to be OpenSSL 3.  LibreSSL reports
`OPENSSL_VERSION_NUMBER 0x20000000L` and has no `OPENSSL_VERSION_MAJOR`; do
not define either to a newer value.

- Keep the OpenBSD and V8 patches; only external-OpenSSL paths, rpaths and
  link dependencies are candidates for removal.
- Rebase the LibreSSL compatibility patches against pristine upstream with
  `diff -u -p`, one file per patch, and keep them separate from upstreamable
  fixes.
- Check that unavailable features fail closed and are documented: secure
  heap, PSK, asynchronous certificate/OCSP callbacks, scrypt, XOF, Ed448,
  X448, SM2, OCB and multi-prime RSA.
- Check that `process.versions.openssl` and JS/test feature gates handle a
  `LibreSSL <version>` string without enabling OpenSSL 3 branches.
- Linux results against Homebrew LibreSSL prove only compile/runtime
  behaviour.  Base-LibreSSL linkage, `port-lib-depends-check`, pledge/unveil,
  W^X and libc++ remain OpenBSD checks.

## Checks and acceptance

- Every version carrier agrees, the package name is newer, and `REVISION` /
  `EPOCH` follow the official rules.
- `distinfo` matches the reviewed upstream and every vendored input; generated
  includes and `distinfo` changed together.
- All patches apply from a clean tree; obsolete patches are gone; dependency
  patch versions and extraction roots are aligned.
- `WANTLIB`, `LIB_DEPENDS`, runtime and test dependencies reflect the new
  build, and `port-lib-depends-check` passes.
- `pkg/PLIST` matches the fake installation, packaging succeeds, and the main
  functionality was actually exercised.
- The Git sources match the tree that was tested, and the final diff contains
  no unrelated changes.

## Common failures

- **`extract` fails on a new distfile:** record the checksum first with a
  reviewed `make makesum`; do not force extraction with an old `distinfo`.
- **A patch applies with fuzz:** regenerate it against the new source; fuzz can
  silently put the change in the wrong place.
- **A generated include references a missing tarball:** run `makesum` again in
  the order the module requires, then re-extract and re-patch.
- **The package installs but a service fails:** use the runtime checks in
  [openbsd-port-packaging](../openbsd-port-packaging/SKILL.md); a successful
  `fake` only proves layout.
- **A dependency moved without a WANTLIB change:** confirm the actual linkage
  with `port-lib-depends-check` and the configure log; some libraries are
  loaded with `dlopen(3)` and are invisible to the checker.

## References

- [Updating ports](https://www.openbsd.org/faq/ports/guide.html#Updates)
- [bsd.port.mk(5)](https://man.openbsd.org/bsd.port.mk.5),
  [packages-specs(7)](https://man.openbsd.org/packages-specs.7)
- [OpenBSD porting special topics](https://www.openbsd.org/faq/ports/specialtopics.html)
- Repository: `docs/UPDATE.md`, `docs/BUILDING.md`, and the port's own history.

## Maintenance & Continuous Learning

When this skill is used to modify the repository, review this skill after the
work. Update it when procedures, tools, configurations, project behavior, or
assumptions have changed, and add reusable knowledge that improves future use.
Correct instructions that proved wrong; keep examples and validation commands
current, and remove obsolete or duplicated guidance. Do not record one-off
execution details. Review linked skills and applicable `AGENTS.md` files for
consistency, validate local references, and run `python3 scripts/validate-agent-knowledge.py --scope worktree` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
