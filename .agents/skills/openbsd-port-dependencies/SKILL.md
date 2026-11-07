---
name: openbsd-port-dependencies
description: Analyze or refresh OpenBSD port dependencies, including generated Cargo, Go, Cabal, and Python metadata in this repository.
---

# OpenBSD Port Dependencies

## Scope and prerequisites

Use for missing dependencies, version constraints, native library linkage, or regenerated dependency manifests. For a release update, coordinate with [openbsd-port-update](../openbsd-port-update/SKILL.md). This skill does not authorize installing packages, changing system configuration, or changing unrelated ports. Do not use it for ordinary application dependency installation outside ports.

Read the target Makefile, inherited `Makefile.inc`, generated includes, upstream lockfiles and build metadata. Use a matching OpenBSD base system, ports tree, and package repository for execution; a foreign host supports static inspection only. Read [module procedures](references/modules.md) for the ecosystem involved and the installed module source before running its targets.

## Workflow

1. Separate direct build, library, runtime, and test requirements from vendored source dependencies. Trace transitives and reverse consumers before widening constraints. From the port directory, use documented queries as needed:

   ```sh
   make show=BUILD_DEPENDS
   make show=LIB_DEPENDS
   make show=RUN_DEPENDS
   make show=TEST_DEPENDS
   make build-depends-list
   make run-depends-list
   make full-build-depends
   make full-run-depends
   make full-test-depends
   ```

   Queries evaluate Makefiles; inspect unfamiliar hooks first. Preserve subpackage-specific dependencies (`-main`, `-gui`, `-server`, `-data`) and distinguish independent `sysutils/uutils` children from `MULTI_PACKAGES`.
2. Prefer official packages for available tools and dependencies that need no changes. Once installation is within the authorized task, use `doas pkg_add package-name` with a verified package name and matching repository. Build only dependencies requiring new ports or changes. A dependency such as `devel/libev:configure` or `devel/abseil-cpp:patch` requires source-stage work; a binary package alone may not satisfy it. Do not set global package or make configuration for convenience.
3. Select the existing module's mechanism. Regenerate `crates.inc`, `modules.inc`, and `cabal.inc`; do not hand-edit generated lists. Treat generator output as a candidate: check successful completion, unexpected diagnostic text, licenses, replacements, and added or removed dependencies before replacing an include.
   These operations require OpenBSD. During a foreign-host update, inspect
   the new upstream lockfile and direct requirements, but leave all generated
   `*.inc`, `distinfo` and packing lists untouched. List each pending file
   and module target in the update table described by the update skill.
   Compare requirements with reverse consumers before crossing a major
   version; a newer registry release does not supersede a justified pin.
   For Python/Rust bindings, inspect the exact sdist for a lockfile and for
   prebuilt foreign executables. A repository workspace lock cannot simply
   replace the lock of a different sdist layout. Prefer the tagged upstream
   workspace when it provides the reviewed lock and Python sources. Trace
   both the cargo module's manifest path and maturin's pyproject selection:
   an explicit manifest can select workspace metadata instead of the Python
   package metadata. Preserve offline and locked builds, and defer any
   resulting packing-list changes to OpenBSD.
   For Cabal sources, inspect the revision field in the existing manifest
   and the matching module's extraction recipe. Hackage can publish a
   revised `.cabal` file separately from the source tarball; the module
   installs that revision before dependency patches run. Reproduce that
   declared input and the port's line-ending normalization when checking
   patches statically. A tarball-only failure does not justify dropping a
   patch or changing dependency bounds.
4. Keep non-registry dependencies reproducible. Use immutable upstream revisions with `DIST_TUPLE`, appropriate extraction paths, local source replacement patches or module mechanisms, and `distinfo`. Examples are Git Cargo dependencies in uutils and codex, and github-cli's local survey replacement. Do not introduce build-time Git clones, `pip install`, `go get`, or arbitrary package-manager downloads.
   For `devel/codex`, inspect upstream `Cargo.toml`, `Cargo.lock`,
   `rust-toolchain.toml`, `crates.inc`, and official `-current` together.
   Upstream may pin V8 to a Git fork while the port maps it to a matching
   registry crate and carries a targeted V8 backport. Verify the exact source,
   commit, version, and patch paths before changing that mapping. Do not edit
   `crates.inc` or `distinfo` outside OpenBSD. Check the upstream Rust toolchain
   pin against the available OpenBSD ports toolchain.
5. Update `LIB_DEPENDS` for native libraries and `WANTLIB` for actual linkage; language source manifests do not replace either. Preserve compiler modules and justified bundled-library exceptions. Validate from a fresh work directory after generation; ordinary configure/build must use fetched, checksummed inputs without new network dependency resolution.

### Strict LibreSSL version metadata

Inspect the exact cargo module and `openssl-sys` build script before relying
on its unknown-LibreSSL fallback. When the base release is unsupported by the
crate's version table, add only that verified release's metadata mapping and
retain rejection of unknown future versions. Confirm downstream consumers use
the actual numeric version and review their FFI cfg branches. Do not disguise
an unknown release as an older supported profile.

If `MODCARGO_CRATES_KEEP += openssl-sys` prevents a module rewrite, preserve
other KEEP entries and explicitly retain `OPENSSL_NO_VENDOR=1` with the base
include/library paths: the module may otherwise omit its environment setup.
Keep the override effective even when generated includes are deferred. Source
lockfiles, registry crates and stale generated metadata must be distinguished;
never hand-edit reserved manifests to conceal their mismatch.

## Acceptance and diagnosis

The dependency graph resolves for the selected architecture and subpackages, generated manifests match upstream metadata and local replacements, and `distinfo` covers every fetched source. Run the relevant checks in [openbsd-port-validation](../openbsd-port-validation/SKILL.md), including `make port-lib-depends-check` after `fake`. Report what was inspected and executed separately.

- Missing dependency: compare upstream metadata, module-added dependencies, query output, and repository package availability; do not invent a package path.
- Resolver conflict: trace upper and lower bounds and API consumers before relaxing constraints. A successful solve does not prove runtime compatibility.
- Unexpected network access: inspect build scripts, omitted Git sources, stale lockfiles, and test-only plans; declare and fetch inputs through ports.
- Wrong native linkage: inspect configure logs, `pkg-config` selection, compiler paths, and `ldd` on OpenBSD; do not silence the dependency checker.
- Missing tests or licensed crate data: record the limitation and repair the source/generation procedure rather than claiming coverage or permission.

See [BUILDING.md](../../../docs/BUILDING.md), [UPDATE.md](../../../docs/UPDATE.md), [bsd.port.mk(5)](https://man.openbsd.org/bsd.port.mk.5), and [port-modules(5)](https://man.openbsd.org/port-modules.5). The reference contains ecosystem-specific module sources.

## Maintenance & Continuous Learning

When this skill is used to modify the repository, review this skill after the
work. Update it when procedures, tools, configurations, project behavior, or
assumptions have changed, and add reusable knowledge that improves future use.
Correct instructions that proved wrong; keep examples and validation commands
current, and remove obsolete or duplicated guidance. Do not record one-off
execution details. Review linked skills and applicable `AGENTS.md` files for
consistency, validate local references, and run `perl scripts/validate-agent-knowledge.pl --scope worktree` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
