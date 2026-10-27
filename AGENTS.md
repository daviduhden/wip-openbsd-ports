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

## Continuous Agent & Skills Maintenance

Agent instructions and skills are living repository artifacts.

Every repository modification MUST include an agent/skills synchronization step.

Before completing any task, inspect the applicable AGENTS.md and SKILL.md files, update the affected instructions, and validate their consistency with the implementation.

A code change without the corresponding agent knowledge maintenance is considered incomplete.

Never claim completion when the synchronization step has been skipped or has failed.

This applies to source, port metadata, dependencies, patches, tests, tools,
workflows, and documentation, including changes to this policy itself. At the
end of each task, inspect all tracked `AGENTS.md`, `.agents/skills/**/SKILL.md`,
and any tool-specific agent/skill files present in the repository. Map changed
paths to the nearest owning instructions and the skills table above; review
cross-cutting skills when the workflow or shared tooling changed.

Update an existing skill when a reusable procedure, assumption, command,
configuration, or validation step changed or was learned. Create a skill only
for a distinct recurring workflow not covered by an existing skill; otherwise
extend the closest skill. Keep specialized agent instructions aligned with
their linked skills. There are currently no checked-in specialized agent files.
Never add cosmetic edits, timestamps, or empty changes to satisfy enforcement.

After editing instructions, verify frontmatter and required headings, inspect
local Markdown links and referenced paths, run
`python3 scripts/validate-agent-knowledge.py --scope worktree`, and review `git diff --check`, status, and the
complete diff. The validator checks changed paths, substantive instruction
diffs, basic skill structure, and resolvable local Markdown links; it cannot
judge semantic relevance, which requires human review. Its default comparison
is against `HEAD`; set `AGENT_SYNC_BASE` to a Git base ref for CI or review of a
branch range. This repository currently has no checked-in CI pipeline, so run
the validator locally; CI integration can invoke the same command once a CI is
introduced.

Every task is blocked from completion until repository changes include at
least one relevant, substantive instruction or skill update, the validator
passes, references are reviewed, and semantic relevance is confirmed. If
these conditions cannot be met, explain why and report the task as incomplete.
When the instructions themselves change, perform one complete consistency
review at the end; repeat validation only after correcting a detected error.

### Shared Agent Knowledge Validation Contract

Use `python3 scripts/validate-agent-knowledge.py --scope worktree` for local
changes and `python3 -m unittest discover -s tests/agent_knowledge_validator -v`
for its contract tests. The validator requires Python 3.11+ and Git, uses only
the Python standard library, and publishes contract version `1.0.0`. All
adopting repositories share the same CLI, AK001-AK006 identifiers, output
schema, and exit codes (`0` pass, `1` policy failure, `2` execution/configuration
error). For a pull request, pass both revisions with
`--scope range --base BASE_REF --head HEAD_REF`; compare from their merge base.

Read [Agent Knowledge Validation Contract](docs/agent-knowledge-validation.md)
for the complete rules, JSON schema, optional repository configuration,
warning semantics, and extension process. AK004 and AK006 can require human
review; their warnings do not prove or disprove semantic correctness. Keep the
canonical script and black-box unittest suite byte-identical across adopting
repositories. Repository-specific requirements belong in the documented TOML
configuration or a stable `AKX...` extension, never in a private fork of the
shared rules. The GitHub PR workflow runs the same tests and range command;
it does not edit files or require secrets.

### Mandatory Definition of Done

- [ ] Repository changes implemented.
- [ ] Relevant agent instructions reviewed.
- [ ] Relevant skills reviewed.
- [ ] Affected AGENTS.md / SKILL.md files updated.
- [ ] Obsolete knowledge removed.
- [ ] New reusable knowledge incorporated.
- [ ] Agent and skill references validated.
- [ ] Automated maintenance checks passed.
- [ ] Final synchronization status reported.

Final reports must include **Agent & Skills Synchronization** with agents and
skills reviewed, instruction files updated, knowledge added or corrected,
validations run, and PASS / FAIL. Never report an unrun check as passed.
