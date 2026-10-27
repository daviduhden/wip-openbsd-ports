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
   version starts a new package revision. If only packaging changes and the
   upstream version is unchanged, bump `REVISION` (add `REVISION = 0` when it
   was absent). Use `EPOCH` only when the version ordering genuinely moves
   backwards, not as a substitute for a correct version.

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
