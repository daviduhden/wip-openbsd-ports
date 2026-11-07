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

## Mandatory compatibility and sandbox review

Any change to source, patches, dependencies, service scripts, or build flags
must include a static OpenBSD compatibility review using
`.agents/skills/openbsd-port-security/SKILL.md`:

1. Map startup, configuration, key access, listeners, helpers, privilege
   changes, reload, and shutdown before changing a policy.
2. Check the cryptographic library actually linked and the target LibreSSL
   API surface; never disable validation or fake a version to compile.
3. Reject simultaneous `PROT_WRITE|PROT_EXEC`. Temporary RW-to-RX transitions
   do not require `USE_WXNEEDED`; reserve it for mappings that are genuinely
   writable and executable at the same time.
4. Replace Linux-only syscalls and procfs assumptions with a checked native
   path, not a stub that reports success.
5. Treat `pledge(2)` and `unveil(2)` as separate boundaries with separate
   inheritance rules. A parent policy does not confine an executed child.
6. Do not add the `exec` or `error` promises. Remove them from existing
   policies when an exec-free or separated design can preserve functionality.
   When it cannot, keep the limitation explicit instead of widening the
   policy. `proc` alone never grants execution.
7. Prefer privilege separation and pre-opened resources over granting a
   helper broader access to the same files, network, or credentials.
8. Compare with current official ports before editing and preserve justified
   local behavior. Record obsolete local patches instead of copying official
   ones blindly.
9. Regenerate changed patches from pristine sources with `diff -u -p`, one
   target per patch, short comments, and `Index:`. Verify the whole series
   applies to a pristine extraction in a temporary directory.
10. Document the remaining risk, unsupported features, and the checks that
    still require a native OpenBSD host. Static review is not runtime proof.

## Shell and Makefile hygiene

- Do not embed Perl or Python in shell scripts, rc.d scripts, Makefiles or
  configuration (`perl -e`, `python -c`, or heredoc code). Use native shell
  for simple logic and a standalone `files/*.sh` helper for complex logic.
- Keep port Makefiles declarative: variables, dependency and patch lists,
  targets, and short commands. Move loops, conditionals and multi-step
  transformations to a helper; keep version and patch data in the Makefile.
- Invoke build-only helpers as `sh ${FILESDIR}/name.sh` and pass path roots
  through arguments or the environment. Helpers use `set -eu`, quote paths,
  and guard unmatched globs.
- Repository tools stay under `tools/`; port build helpers stay under the
  port's `files/`. Do not add a second copy of data that the Makefile owns.
- Verify with `sh -n`, `shellcheck -s sh`, `perl -c` and the relevant test
  suite. State that OpenBSD `make`, package and runtime checks remain
  outstanding when no matching host was used.

See [Shell and Makefile refactoring](docs/build-script-refactoring.md) for the
helper layout and the current port-specific exceptions.

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
   For every version update, first establish the newest stable upstream
   release and inspect the matching port in official OpenBSD `-current`.
   Compare official changes with local changes file by file; preserve local
   behavior unless evidence shows it is obsolete. Regenerate retained patches
   against pristine upstream sources with `diff -u -p`, an `Index:` header,
   and a rationale whose lines are at most 72 columns. Review the port's
   `Makefile` and `README` after the source change. See `docs/UPDATE.md`.
   Outside OpenBSD, do not regenerate `distinfo`, `pkg/PLIST*`, or generated
   `*.inc` files. Record each deferred artifact and the checks still needed.
   For `devel/codex`, use read-only subagents for independent upstream,
   official-port, local-patch, Cargo/V8, and OpenBSD process-security reviews
   when available. Reconcile their evidence before editing. Follow the
   Codex-specific gates in the update, dependency, and security skills; keep
   daemon/package-manager behavior and fail-closed sandbox handling intact.
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
- For a customized port with an official counterpart, compare effective
  `REVISION` values and set the local value above the official one to avoid
  package-name collisions. An omitted official `REVISION` means zero.
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

## LibreSSL-native ports

`lang/node` is intentionally built against the base-system LibreSSL, not
`security/openssl`.  Its LibreSSL patches live in `lang/node/patches/` and
rely on Node's legacy `deps/ncrypto` backend, which is selected because
LibreSSL reports `OPENSSL_VERSION_NUMBER 0x20000000L` and does not define
`OPENSSL_VERSION_MAJOR`.

When changing `lang/node` or a port with a similar LibreSSL adaptation:

1. Preserve the official OpenBSD patches for platform, V8, CET, memory,
   pledge/unveil, W^X and build integration.  Only the `eopenssl` rpath in
   `patch-common_gypi` is OpenSSL-specific.
2. Keep `--shared-openssl` with base paths, `WANTLIB += crypto ssl`, and no
   `security/openssl` dependency unless a new API requirement is demonstrated
   and documented.
3. Rebase compatibility patches against pristine upstream sources with
   `diff -u -p`; never generate a patch from an already-patched tree.
4. Do not emulate OpenSSL 3 providers or fake a version number to make
   configure pass.  Prefer the real LibreSSL primitive, then a guarded
   feature removal, then a small adapter.  Never weaken certificate or key
   validation to obtain a build.
5. Keep `--secure-heap`, `pskCallback`, asynchronous certificate/OCSP
   callbacks and other unavailable features fail-closed.  Document every
   functional loss in the port `README`.
6. Treat `process.versions.openssl` as `LibreSSL <version>`; test helpers and
   JS feature gates must not parse it as an OpenSSL release.
7. A Linux build against Homebrew LibreSSL is compile/runtime evidence only.
   Base-LibreSSL linkage, pledge/unveil, W^X, libc++ and the OpenBSD package
   still require native validation.

## XERJ port (devel/xerj)

`devel/xerj` is a Cargo-workspace port pinned to an upstream prerelease.
Its manifest is `engine/Cargo.toml`, and only the `xerj-server` package
provides the installed `xerj` binary.  Preserve that selection unless a
tested change requires otherwise.

When maintaining it:

1. Check upstream tags, releases and the pinned commit before updating.
2. Read the whole `engine` workspace and `Cargo.lock`; do not assume the
   whole workspace must be built.
3. Review new and removed crates, features and native build scripts.
4. Re-audit OpenBSD cfg branches and Linux-only syscalls/constants.
5. Check target-cpu/ISA requirements and do not use `target-cpu=native`.
6. Keep OpenBSD-specific patches separate, rebase them on pristine
   upstream, and use `diff -u -p` with an `Index:` header and comments
   wrapped to 72 columns.
7. Keep `Makefile` dependencies and feature flags current, including the
   system SQLite/zstd choice and the `OPENSSL_NO_VENDOR` setting.
8. Keep unavailable or unverified features fail-closed; do not disable
   TLS, authentication or validation to make a build pass.  Document
   packaging decisions, feature losses and pending OpenBSD checks in the
   port `README` and update report.
9. Never generate `distinfo`, `pkg/PLIST` or a Cargo `*.inc` outside an
   OpenBSD ports tree.  Record their absence and the exact regeneration
   targets.
10. Use independent read-only subagents for upstream, Cargo, native,
    architecture, security and packaging questions.
11. Separate static findings from real OpenBSD build/runtime evidence.
12. Run tests package-scoped to `xerj-server` with a writable `HOME`;
    workspace-wide tests also compile `xerj-autoindex` tests that still
    reference the Linux-only `RLIMIT_AS`.

The detailed update checklist is in
`.agents/skills/openbsd-port-update/SKILL.md`.

## Verification and delivery

Choose the checks that match the change and record the exact commands,
environment, and result. At minimum, inspect `git diff --check`, `git status`,
and the complete diff. When a patch changes, reconstruct the series by applying
every `patches/patch-*` file to a pristine extraction in a `mktemp -d` tree and
compare the result with the edited tree; a patch that only looks correct is not
evidence that the series applies. Run `prove -v tools/t/perl-tools.t` after
changing the Perl tools. If execution is prohibited or the host is not a
matching OpenBSD system, perform static review only and state that build,
package, and runtime validation remain outstanding. Do not run
`bulk-build.pl` or `gen-manifests-and-test.pl` as a substitute for reviewing a
change; they install packages, build ports, and may modify the host.

Commit only the files needed for the task. Use an imperative subject, usually
prefixed with `category/port:` when the change is port-specific. Do not commit
`audit/`, `logs/`, work directories, packages, or downloaded distfiles. Report
what was tested, what was not, and which checks require a real OpenBSD host.

## Immutable GitHub Actions pins

The only workflow is `.github/workflows/agent-knowledge-validation.yml`.
Third-party actions stay pinned to immutable full-length commit SHAs, never
floating tags, branches, or short SHAs. The trailing comment records the
reviewed upstream release for human comparison:

| Action | Release | Commit SHA |
| --- | --- | --- |
| `actions/checkout` | `v7.0.1` | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `actions/upload-artifact` | `v7.0.2` | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` |
| `actions/cache` | `v6.1.0` | `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` |

These pins were verified against upstream stable releases on 2026-11-07.
`upload-artifact` and `cache` are not used yet; keep the map for the next
workflow that needs them.

- Write each pin as `owner/action@<40-hex-sha> # vX.Y.Z`.
- Confirm the stable upstream release and its immutable commit before editing.
  Replace the SHA and the trailing version comment in the same change.
- Preserve triggers, permissions, job names, concurrency, and step behavior.
  Do not add automatic triggers or unrelated workflow changes.
- Review `git diff --check` and the complete workflow diff, then run
  `actionlint .github/workflows/*.yml` and `yamllint` when a tracked
  configuration exists. These are static checks, not a workflow run.

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
`perl scripts/validate-agent-knowledge.pl --scope worktree`, and review `git diff --check`, status, and the
complete diff. The validator checks changed paths, substantive instruction
diffs, basic skill structure, and resolvable local Markdown links; it cannot
judge semantic relevance, which requires human review. Its default comparison
is against `HEAD`; use `--scope range --base BASE_REF --head HEAD_REF` for
branch review. The GitHub workflow runs only on manual `workflow_dispatch` and
runs the contract tests and the worktree validator; run the same commands
locally before delivery.

Every task is blocked from completion until repository changes include at
least one relevant, substantive instruction or skill update, the validator
passes, references are reviewed, and semantic relevance is confirmed. If
these conditions cannot be met, explain why and report the task as incomplete.
When the instructions themselves change, perform one complete consistency
review at the end; repeat validation only after correcting a detected error.

### Shared Agent Knowledge Validation Contract

Use `perl scripts/validate-agent-knowledge.pl --scope worktree` for local
changes and `prove -v tests/agent_knowledge_validator`
for its contract tests. The validator requires Perl 5.36+ and Git, uses only
core Perl modules, and publishes contract version `2.0.0`. All
adopting repositories share the same CLI, AK001-AK006 identifiers, output
schema, and exit codes (`0` pass, `1` policy failure, `2` execution/configuration
error). For a pull request, pass both revisions with
`--scope range --base BASE_REF --head HEAD_REF`; compare from their merge base.

Read [Agent Knowledge Validation Contract](docs/agent-knowledge-validation.md)
for the complete rules, JSON schema, optional repository configuration,
warning semantics, and extension process. The migration record is
[Python tooling migration](docs/python-migration.md). AK004 and AK006 can require human
review; their warnings do not prove or disprove semantic correctness. Keep the
canonical Perl validator and its black-box `Test::More` suite equivalent across
adopting repositories. Repository-specific requirements belong in the
documented TOML configuration or a stable `AKX...` extension, never in a
private fork of the shared rules. Do not reintroduce Python for project
tooling: `lang/python` and the `py-*` ports are upstream port content, not
repository scripts. The manually dispatched GitHub workflow runs the same tests
and the worktree command; it does not edit files or require secrets.

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

### LibreSSL and Codex audit follow-through

For LibreSSL-sensitive ports such as `www/lynx`, inspect the actual base
LibreSSL headers for the target release, preserve certificate-chain and
identity validation, and review any explicit user override separately from
default rejection. When unveil is active, include only the configured CA and
client identity files actually read. For `devel/codex`, compare the exact
upstream tag and lockfile with official `-current` and local generated Cargo
metadata; do not hand-edit reserved generated files outside OpenBSD. Trace
shell, daemon and sandbox policy through process launch, and never imply that
pledge/unveil confines exec children without verified exec restrictions.

### Port description style

Keep port `COMMENT` values concise and follow the packaging skill: no package
name and no trailing period. Keep `pkg/DESCR` concise, with ordinary prose
wrapped to 80 columns; preserve indivisible URLs, command examples and
meaningful list structure. Start every installed `pkg/README` with the
canonical `${PKGSTEM}` OpenBSD banner. Wrap ordinary prose consistently, but
preserve code blocks, tables, paths and command arguments. Maintainer READMEs
remain separate from installed package instructions.
