---
name: openbsd-port-validation
description: Validate an OpenBSD port through fetch, checksum, extract, patch, configure, build, fake, PLIST, dependency, package, and functional test stages, with honest evidence of what was actually run.
---

# Validate an OpenBSD port

Use this skill before delivering, synchronizing, or claiming that a port
change works. It applies to new ports, updates, dependency refreshes, patch
rewrites, and packaging changes. Do not use it as a substitute for reading the
change or for an authorized runtime test. A validation run installs
dependencies, writes work directories, and can modify the host; obtain the
needed authorization first.

## Prerequisites

Use a matching OpenBSD base, ports tree, package repository, and architecture.
Confirm `WRKOBJDIR`, `DISTDIR`, `PACKAGE_REPOSITORY`, and the privileged
helper configured for the tree. Read the port's Makefile and generated
includes. Inspect `git status` and preserve uncommitted work before any clean
or replacement.

Choose the smallest validation that answers the question, then state the
limits. The stages below are cumulative; skipping one does not invalidate the
earlier ones, but it must be reported. If execution is prohibited or the host
is not a matching OpenBSD system, stop after the static checks and report the
build, package, and runtime validation as outstanding.

## Procedure

### 1. Static and metadata checks

```sh
make show=PKGNAME
make show=PKGNAMES
make show=BUILD_DEPENDS
make show=LIB_DEPENDS
make show=RUN_DEPENDS
make show=TEST_DEPENDS
make show=WRKSRC
make show=PATCHDIR
make checksum
```

Check the repository patch format for every touched patch:

```sh
ksh .agents/skills/openbsd-port-patches/scripts/check-patch-style.ksh \
    $(find category/port/patches category/port/files -name 'patch-*' 2>/dev/null)
```

`make checksum` verifies the recorded `distinfo`; `make makesum` **rewrites**
it. Use `makesum` only when the new inputs were reviewed and the intent is to
update the checksums. Check the diff and the upstream provenance either way.
For a port using generated manifests, confirm the include is present and was
produced by its module target, not hand-edited.

### 2. Fetch and extract

```sh
make fetch
make checksum
make extract
make show=WRKSRC
```

`fetch` writes to `DISTDIR` and may use the network. `extract` installs ports
dependencies when needed. Inspect the extracted source root and confirm the
port patches will be applied relative to it.

### 3. Patch, configure, and build

```sh
make patch
make configure
make build
```

A failed patch can leave a partially modified work directory. Read rejects and
logs before retrying; do not assume a second `make patch` is meaningful. Read
the configure log for accidentally detected libraries and disabled features.
`build` proves compilation only, not installation or runtime behavior.

### 4. Fake installation and package

```sh
make fake
make update-plist
make port-lib-depends-check
make package
```

`fake` populates `WRKINST`. `update-plist` proposes a packing list from that
tree; review every change instead of accepting it. `port-lib-depends-check`
compares built linkage with `WANTLIB` and `LIB_DEPENDS`; it cannot see
libraries loaded with `dlopen(3)`. `package` proves package assembly, not that
the package installs or that the service works.

For `MULTI_PACKAGES`, check every `PLIST-*` and the subpackage dependencies.
Do not validate only `-main`.

### 5. Package installation and runtime

```sh
doas pkg_add -v /path/to/package.tgz
pkg_info -L pkgname
```

Installation and removal change the host. Use an isolated test host or an
explicitly authorized environment. Verify that files land where the PLIST
says, that samples are created without overwriting user configuration, that
owners and modes are correct, and that `pkg_delete` leaves no unexpected
files. Never install privileged software or enable a service merely to make a
documentation check pass.

For a CLI, test `--help`, `--version`, and a representative non-destructive
operation. For a daemon, test configuration validation, initialization,
`rcctl start`, status, reload if supported, and `rcctl stop`; inspect logs and
the process user. For a GUI, verify that it starts and exits without a missing
library or display error. State which of these were actually run.

### 6. Tests

```sh
make test
```

`make test` is the framework target and prepares `TEST_DEPENDS`. `make do-test`
runs the port's own target and can bypass that setup; use it only when the port
documents the behavior you need. Some suites need network access or a live
service. Record that explicitly. A skipped test, an unsupported exit status,
and a test that only checks compilation are not passes.

### 7. Review the result

```sh
git diff --check
git status --short
git diff --stat
```

Confirm that only intended files changed. Inspect generated includes,
`distinfo`, `pkg/PLIST*`, patches, `pkg/README`, and rc.d scripts together.
Report the exact commands, host/release/architecture, work directory, and
failures. If a stage was not run, say so.

## Evidence levels

| Level | Evidence | What it does not prove |
| --- | --- | --- |
| Static | Makefile parsing, `show=`, `checksum`, diff review, `portcheck` | Build, package, runtime |
| Built | `configure` and `build` succeed | Installation layout, packaging |
| Packaged | `fake`, `update-plist`, `port-lib-depends-check`, `package` succeed | Package installation, service behavior |
| Installed | Package installs and files match PLIST | Functional correctness |
| Functional | CLI/daemon/GUI exercised on OpenBSD | Untested paths and configurations |

## Acceptance and diagnosis

Accept only when the claimed level is supported by captured output. A clean
`git diff --check` is not a build. A successful package is not a working
service.

- **Checksum failure:** compare the upstream URL, filename, and recorded
  version. Do not overwrite `distinfo` until the new input is identified.
- **Configure picks up an undeclared library:** add the dependency or disable
  the option; retest in a clean tree. A bulk build on a machine without the
  package is the useful check.
- **`port-lib-depends-check` reports a missing library:** inspect the actual
  linkage and the dependency's package; do not silence it with an unrelated
  `WANTLIB` entry.
- **`update-plist` removes files:** determine whether the build stopped
  installing them or whether the PLIST was wrong. Do not re-add blindly.
- **A service starts manually but not through rcctl:** check `daemon`,
  `daemon_user`, `daemon_execdir`, `rc_bg`, environment handling, ownership,
  and writable state directories.

## References

- [OpenBSD ports testing](https://www.openbsd.org/faq/ports/testing.html)
- [bsd.port.mk(5)](https://man.openbsd.org/bsd.port.mk.5),
  [pkg_create(1)](https://man.openbsd.org/pkg_create.1),
  [pkg_add(1)](https://man.openbsd.org/pkg_add.1),
  [rc.subr(8)](https://man.openbsd.org/rc.subr.8)
- Repository: `docs/BUILDING.md`, `docs/UPDATE.md`, and the port's `pkg/`
  files.
