---
name: openbsd-port-create
description: Create a new OpenBSD port or nested subport from upstream sources, including Makefile, distfiles, licenses, dependencies, patches, PLIST, and initial validation.
---

# Create an OpenBSD port

Use this skill when a port, subport, or port group genuinely does not exist in
the official OpenBSD tree. For an existing port moving to a new release, use
[openbsd-port-update](../openbsd-port-update/SKILL.md). For packaging changes
to an existing port, use [openbsd-port-packaging](../openbsd-port-packaging/SKILL.md).
This skill does not authorize a host bootstrap, global package changes, or an
OpenBSD CVS commit.

## Prerequisites

Read [BUILDING.md](../../../docs/BUILDING.md), the relevant parts of the
[OpenBSD porting guide](https://www.openbsd.org/faq/ports/guide.html), and the
matching tree's `infrastructure/templates/Makefile.template`. Work from a
matching OpenBSD base, ports tree, and package repository. Verify that the
port is absent from the official tree with a current checkout or the official
source browser, not only with a local `ls`.

Establish the upstream release, source archive, license, build system, test
suite, install layout, and runtime requirements. Check whether the software
needs a dedicated account or a service. Inspect the closest existing official
port and the module that actually matches upstream metadata; do not choose a
module by analogy.

## Procedure

1. Select the primary category from the existing tree and choose
   `category/port`. Use `category/group/port` only for an independently
   buildable subport group with a shared parent `Makefile.inc`. Do not model a
   `MULTI_PACKAGES` port as a directory group or vice versa.
2. Start from the official template and fill the minimum: `COMMENT`,
   `DISTNAME` (or `GH_*`, `MODGO_*`, `MODPY_*`, or `MODCABAL_*`), `CATEGORIES`,
   `HOMEPAGE`, `PERMIT_PACKAGE`, and the real license comment. Use a normal
   release archive where upstream publishes one; use `DIST_TUPLE` with a full
   commit hash only for a real Git-only dependency and set `WRKDIST` when the
   extraction layout requires it.
3. Select the build module from upstream metadata. Add only the native
   `WANTLIB` and `LIB_DEPENDS`, build tools, runtime tools, and test-only tools
   that are actually required. Keep source-stage dependencies such as
   `devel/libev:configure` or `devel/abseil-cpp:patch` as source dependencies
   when a binary package cannot satisfy them.
4. Fetch and record checksums. `make makesum` downloads and **rewrites**
   `distinfo`; review the files and the diff. Then inspect the extracted source:

   ```sh
   make makesum
   make extract
   make show=WRKSRC
   ```

5. Build in the open. Run `make configure` and `make build`, read the
   configuration log, and check for silently detected or missing software.
   Do not add a patch until a supported Makefile variable, configure flag, or
   module option has been ruled out.
6. Create patches with [openbsd-port-patches](../openbsd-port-patches/SKILL.md).
   Keep each patch tied to one target file and record why it exists. Re-run
   `make clean patch` or a fresh `make patch` after generating them.
7. Install into the fake root, generate the packing list, and fix packaging:

   ```sh
   make fake
   make update-plist
   make port-lib-depends-check
   make package
   ```

   Review every line of `pkg/PLIST`; `update-plist` proposes a list, it does
   not justify it. Follow [openbsd-port-packaging](../openbsd-port-packaging/SKILL.md)
   for `DESCR`, `README`, `@sample`, users, and rc.d scripts.
8. If the port creates an account, allocate the lowest free fixed ID from the
   official `infrastructure/db/user.list`, add the matching `@newuser` /
   `@newgroup` entries, and prepare the registry change separately. Never copy
   an ID from an example or from this repository's stale snapshot.
9. Test the software, not only the build. Use `make test` when the framework
   can prepare `TEST_DEPENDS`; use the port's documented `do-test` target only
   when you understand what it bypasses. Exercise CLI output, a daemon's
   startup and shutdown, or a GUI's launch as applicable. Network-dependent
   tests must be declared, not hidden.
10. Complete [openbsd-port-validation](../openbsd-port-validation/SKILL.md),
    then prepare the delivery with [openbsd-port-cvs](../openbsd-port-cvs/SKILL.md).
    A Git commit is not an official submission.

## Checks and acceptance

- The port is absent officially, the category and group layout are correct,
  and the Makefile uses the matching module rather than a private build system.
- `distinfo` covers every fetched input, including every `DIST_TUPLE` entry.
- `make patch` applies from a clean extraction without rejects or unexplained
  fuzz; generated manifests, if any, were produced by their module targets.
- `make fake` installs the intended files, `pkg/PLIST` records them with the
  right annotations, `make port-lib-depends-check` passes, and `make package`
  succeeds.
- A package installs and the main program, daemon, or GUI starts on the target
  OpenBSD release. Record exactly which of these were executed.
- `git diff --check` is clean and no build products, distfiles, packages,
  `audit/`, or `logs/` are staged.

## Common failures

- **Build succeeds but the binary is missing from the package:** inspect the
  `fake` tree and `do-install`; do not hide the file with a broad PLIST entry.
- **Configure found a dependency that is not declared:** add the real
  `LIB_DEPENDS`/`WANTLIB` or disable the option. A bulk build on a machine
  without the package exposes accidental detection.
- **A new file is unregistered:** regenerate the PLIST, then compare the fake
  tree and PLIST rather than appending a path blindly.
- **A daemon works only when started by hand:** the rc.d script, ownership,
  `daemon_execdir`, environment, and writable state paths are part of the port,
  not an afterthought.
- **The port needs network during `build`:** declare and fetch the input with
  `DIST_TUPLE`/`distinfo`, or use the module's offline mechanism. Do not add a
  build-time clone, `pip install`, `go get`, or package-manager download.

## References

- [OpenBSD porting guide](https://www.openbsd.org/faq/ports/guide.html)
- [bsd.port.mk(5)](https://man.openbsd.org/bsd.port.mk.5),
  [port-modules(5)](https://man.openbsd.org/port-modules.5)
- [pkg_create(1)](https://man.openbsd.org/pkg_create.1),
  [packages(7)](https://man.openbsd.org/packages.7)
- Repository: `docs/BUILDING.md`, `docs/UPDATE.md`, `user.list`, and the
  closest existing port in the same family.
