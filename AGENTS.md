# AGENTS.md

This repository is a working overlay of OpenBSD ports maintained in Git. It is
not a complete ports tree: there is no root `Makefile`, no `infrastructure/`,
and no category `Makefile`. The authoritative inventory is:

```sh
./fetch-ports.ksh --list
```

Use that list instead of hard-coded counts. Ports live at `category/port`, with
`category/group/port` for a real subport group such as
`sysutils/uutils/awk`. Distinguish independent directory subports from one port
with `MULTI_PACKAGES` (`games/assaultcube`, `net/onionshare`). Never assume a
single build system or module: Python, Go, Cargo, Cabal, CMake, Meson,
autoconf, and custom make ports all exist here.

Read `docs/BUILDING.md` for setup and per-port workflows, and `docs/UPDATE.md`
for version updates. The specialized procedures are in `.agents/skills/`:

| Skill | Use when |
| --- | --- |
| `openbsd-port-create` | Adding a port or subport that does not exist officially. |
| `openbsd-port-update` | Moving an existing port to a new upstream release or revision. |
| `openbsd-port-dependencies` | Changing dependencies or regenerating Cargo, Go, Cabal, or Python metadata. |
| `openbsd-port-patches` | Creating, rebasing, reviewing, or deleting patches. |
| `openbsd-port-validation` | Proving what was fetched, built, packaged, and actually tested. |
| `openbsd-port-packaging` | Editing `pkg/`, PLIST annotations, users, services, and installed files. |
| `openbsd-port-cvs` | Preparing CVS diffs or source archives for OpenBSD. |
| `openbsd-port-security` | Auditing crypto, sandboxing, privileges, or service exposure. |
| `openbsd-ports-sync` | Moving tested sources between this Git checkout and `/usr/ports`. |

## Ground rules

1. Prefer the official OpenBSD ports infrastructure, module, and conventions
   over repository-specific inventions. Read the local module source in the
   matching tree before relying on a target or variable.
2. Use OpenBSD `make` in a matching OpenBSD ports tree. `bmake` on another
   system can parse some Makefiles but does not prove that a port builds or
   runs on OpenBSD. Use `ksh`, POSIX shell tools, and native utilities; do not
   introduce GNU make, Bash, or GNU-only behavior when native tools suffice.
3. Use `doas` only for operations that need it and only when the task
   authorizes them. Do not change global package repositories, `/etc/mk.conf`,
   mounts, `wxallowed`, or system services as a shortcut.
4. Treat `CVS/` directories and their metadata as read-only. Never delete them,
   overwrite them, or represent them as ordinary Git content. A Git commit is
   not an OpenBSD submission.
5. Never hand-edit `crates.inc`, `modules.inc`, `cabal.inc`, or `distinfo`.
   Regenerate them with the supported target, write generator output to a
   temporary file, check the exit status and contents, then replace the
   tracked file. Prefer `make update-plist` for `pkg/PLIST*`; a manual PLIST
   edit is acceptable only when the installed layout is unambiguous, and must
   still be followed by `make fake`/`update-plist` validation on OpenBSD.
   Network access is allowed for maintainer regeneration and fetching, not for
   ordinary configure or build.
6. Keep patches minimal, specific, and reviewable. Generate them from a
   clean extraction with `make update-patches`, which uses `diff -u -p` and
   adds the ports `Index:` header. Each patch has one target file, one
   `Index:` line with a relative path, `--- path.orig` / `+++ path`, a short
   comment above the header wrapped to 72 columns, and the repository's
   `patch-...` naming. New files use `--- /dev/null`. Do not add timestamps,
   CRLF endings, CVS keywords, or an SPDX identifier unless the licensing of
   the authored material is established. Keep upstream-ready patches separate
   from ports-only patches, and keep `files/<dependency>/` patches relative to
   that dependency's extraction root. Run the patch style check described in
   the patches skill after editing or rebasing.
7. Do not add dependencies, flavors, modules, or custom download mechanisms
   without a demonstrated need. Prefer official binary packages for tools and
   dependencies that do not need to be rebuilt. Use pinned `DIST_TUPLE`
   revisions or normal `distinfo` inputs for everything the build consumes.
8. Preserve user changes. Inspect `git status`, `git diff`, and the destination
   tree before replacing files. Do not clean, reset, or overwrite unrelated
   work.
9. Never claim that a port was fetched, compiled, packaged, installed, or
   tested unless the command was actually run on OpenBSD with the matching
   tree. Static inspection, a successful `bmake -n`, and a green parser test
   are not build or runtime evidence.
10. Do not run destructive or host-wide operations without explicit
    authorization. This includes the default `fetch-ports.ksh` bootstrap,
    `--no-provision`, `clean=all` on user work, package upgrades, `pkg_delete`,
    service activation, and filesystem or firewall changes.

## Working in this repository

- Keep transient analysis, logs, and scratch results in `audit/` or `logs/`;
  both are ignored and must not be committed.
- Do not add ignored audit material to a port. The copy helper excludes
  top-level `audit/` and `logs/` directories, but keep such notes outside port
  directories anyway.
- When a port has an official counterpart, compare against a current official
  checkout instead of assuming the local copy is authoritative. A missing local
  directory does not prove that a port is new.
- New ports need a `pkg/DESCR`, a reviewed `pkg/PLIST`, a `distinfo`, and an
  account allocation when they create users or groups. Check the official
  `infrastructure/db/user.list`, not only this repository's snapshot.
- `user.list` is a merged snapshot. Never replace the destination registry
  wholesale; merge only the accounts for the selected ports and preserve
  upstream rows and IDs.
- `fetch-ports.ksh --copy-only TREE [port ...]` is the safe overlay. With no
  port arguments it copies every port. It replaces selected port directories,
  keeps nested CVS metadata, and writes recovery data under `.wip-backups/`
  and `.wip-changes/`. Review those artifacts; they are aids, not a CVS
  inventory.
- Use subagents for separable analysis (build systems, patches, packaging,
  security, CVS) when they are available. Give each a read-only scope, require
  file/line evidence, and reconcile contradictions before editing.

## Verification and delivery

Choose the checks that match the change and record the exact commands,
environment, and result. At minimum, inspect `git diff --check`, `git status`,
and the complete diff. Run `prove -v tools/t/perl-tools.t` after changing the
Perl tools. If execution is prohibited or the host is not a matching OpenBSD
system, perform static review only and state that build, package, and runtime
validation remain outstanding. Do not run `bulk-build.pl` or
`gen-manifests-and-test.pl` as a substitute for reviewing a change; they
install packages, build ports, and may modify the host.

Commit only the files needed for the task. Use an imperative subject, usually
prefixed with `category/port:` when the change is port-specific. Do not commit
`audit/`, `logs/`, work directories, packages, or downloaded distfiles. Report
what was tested, what was not, and which checks require a real OpenBSD host.

## Maintaining these instructions

- Change this file when a repository-wide convention changes.
- Change a `SKILL.md` when its specialized procedure changes.
- Add a skill only for a distinct, recurring workflow; do not create empty or
  overlapping skills.
- Remove instructions for tools or procedures that no longer exist.
- Keep this documentation out of release tracking and version inventories.
  Update it as part of the change that alters the convention, without
  rewriting unaffected sections.
