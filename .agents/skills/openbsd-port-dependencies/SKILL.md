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
4. Keep non-registry dependencies reproducible. Use immutable upstream revisions with `DIST_TUPLE`, appropriate extraction paths, local source replacement patches or module mechanisms, and `distinfo`. Examples are Git Cargo dependencies in uutils and codex, and github-cli's local survey replacement. Do not introduce build-time Git clones, `pip install`, `go get`, or arbitrary package-manager downloads.
5. Update `LIB_DEPENDS` for native libraries and `WANTLIB` for actual linkage; language source manifests do not replace either. Preserve compiler modules and justified bundled-library exceptions. Validate from a fresh work directory after generation; ordinary configure/build must use fetched, checksummed inputs without new network dependency resolution.

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
consistency, validate local references, and run `python3 scripts/validate-agent-knowledge.py --scope worktree` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
