# Python tooling migration to Perl

This note records the migration of repository-owned Python tooling to Perl.
It is maintenance documentation, not a port or release inventory.

## Inventory before migration

The repository contained exactly two project-owned Python files:

| Path | Purpose | Classification |
| --- | --- | --- |
| `scripts/validate-agent-knowledge.py` | Canonical Agent Knowledge Validation CLI | Shared contract artifact, copied byte-identically into adopting repositories |
| `tests/agent_knowledge_validator/test_validator.py` | Black-box `unittest` suite for that CLI | Shared contract artifact |

No other repository script used a Python shebang. There was no Python in
`fetch-ports.ksh`, `tools/*.pl`, `tools/t/`, or `scripts/`. The GitHub workflow
ran `actions/setup-python`, the unittest suite, and the validator range mode.

Python found under `category/py-*`, `lang/python`, and upstream patches is
third-party port content. It is not repository tooling and was not rewritten.
`lang/node` uses the ports Python module only as an upstream build dependency.

References to the two scripts existed in `AGENTS.md`, nine
`.agents/skills/*/SKILL.md` maintenance sections, `tools/t/README`,
`docs/agent-knowledge-validation.md`, `.agent-knowledge-validator.toml`, and
the GitHub workflow. All were updated.

Ignored `audit/*.py` helpers were transient analysis artifacts; they are not
tracked and were left outside the migration.

## Implementation

`scripts/validate-agent-knowledge.pl` is a complete rewrite, not a
transliteration. It stays a single executable because the shared contract
distributes exactly one validator file and one test file; splitting private
modules would multiply the synchronization surface across repositories.

- `use strict`, `use warnings`, `use utf8`, and UTF-8 stdout/stderr.
- Only core modules: `Getopt::Long`, `JSON::PP`, `Encode`, `File::Spec`,
  `File::Basename`, `Cwd`, `IPC::Open3`, `IO::Select`, `Symbol`; the test suite adds
  `File::Temp`, `File::Path`, `File::Copy` and `Test::More`.
- Git is invoked with list-form `open3` (`git -C ROOT ...`), never through a
  shell. Output is decoded as UTF-8 with replacement for Git metadata and
  strict UTF-8 for instruction/config files.
- The documented TOML subset is parsed directly: `[validator]`, nested tables
  for `required_headings`, `required_phrases` and `strict_text`, arrays,
  strings, booleans and integers. There is no `eval`, no Python, and no
  external TOML dependency.
- Path classification reproduces Python `fnmatch.fnmatchcase` (including `*`
  matching `/`), `PurePosixPath` names, and lexical plus symlink-aware link
  resolution.
- The seven checks keep the same order and messages: AK001, AK002, AKX001,
  AK003, AK004, AK005, AK006. The JSON schema remains version `1.0`; the
  contract version is `2.0.0`.

`tests/agent_knowledge_validator/test_validator.t` is a `Test::More` port of
the Python black-box suite, extended with strict-text, inline-path,
required-heading and UTF-8 coverage. Fixtures use `src/example.txt` so the test
tree contains no Python.

## Behavioural verification

Before deleting the Python files, both implementations were run against
identical Git fixtures. Text stdout and exit codes matched for:

- clean worktree, code-only change, code plus `AGENTS.md`, code plus skill;
- cosmetic knowledge edit, malformed skill, broken link;
- untracked, renamed, deleted, staged and unstaged files;
- valid range, missing revision, invalid configuration, usage error;
- explicit exclusion, conflicting directives, JSON output, outside a Git
  repository;
- required headings and phrases, strict-text rules, inline path checks,
  custom instruction globs, duplicate instructions, minimum changed lines;
- UTF-8 knowledge content, percent-encoded paths, fragments and absolute
  links, symlinked files and symlinked parent directories escaping the
  repository, `.agent.md` skill references.

Intentional differences, all on invalid or hostile input:

- `--help` names the Perl implementation and contract 2.0.0; it still
  documents `--scope {worktree,range}` and `--format {text,json}`.
- CLI usage/error text differs, but every tested case keeps exit code 2.
- `minimum_changed_lines = true` is rejected (exit 2). TOML booleans are not
  integers; the Python validator accepted the boolean as `1`.
- A link containing a percent-encoded NUL is reported as a broken reference.
  The Python validator raised an uncaught `ValueError` with no report.
- Duplicate TOML keys and duplicate table declarations are rejected (exit 2),
  matching `tomllib`.
- Invalid fnmatch ranges such as `[z-a]` are non-matches instead of a Perl
  regex exception; the gate still runs.

`prove -v tests/agent_knowledge_validator` runs 82 assertions. The validator
also passes in text and JSON modes on this worktree, including a range run.
After deleting the Python files, the differential harness was rerun with the
Python validator loaded from `git show HEAD:` and the current Perl script;
every scenario still matched.

## Compatibility consequence

Contract 2.0.0 is a deliberate break from the Python 1.0.0 artifact. The CLI,
JSON schema and exit codes did not change, but `contract_version` did. Each
adopting repository must update the validator, the test suite, its
configuration, CI, instructions and skills together. Until that happens, those
repositories remain on 1.0.0; this repository does not claim they were
migrated.

## Remaining validation

- Run `prove` and both CLI modes with the base-system Perl on the target
  OpenBSD release. GitHub Actions uses the runner Perl, which is not OpenBSD.
- Run a real pull-request range validation with fetched history.
- Keep the Perl validator and `test_validator.t` synchronized with the other
  adopting repositories when contract 2.0.0 is rolled out.
