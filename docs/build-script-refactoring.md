# Shell and Makefile refactoring

This note records the removal of inline Perl/Python and the extraction of
complex recipe logic from port Makefiles. It covers repository tooling and
port build hooks, not upstream program code.

## Audit result

The repository had no `perl -e`/`-E`, `python -c`, or heredoc-embedded
Perl/Python in POSIX shell scripts, rc.d scripts, Makefiles, or configuration
files. The only inline execution was in the native Codex sandbox driver:

- `devel/codex/files/openbsd-sandbox-regress.pl` passed Perl source to
  `perl -e` for write, mkdir, chmod/utime, fchown and TCP connection probes.
- `tools/t/perl-tools.t` used `perl -e` to exercise the command-capture helper.

Both now use standalone scripts:

- `devel/codex/files/openbsd-sandbox-probe.pl` implements the probes with a
  small operation dispatcher. The driver copies it into the disposable
  workspace so the sandbox profile can read it, then invokes it by path.
- `tools/t/fixtures/{capture-output,exit-7,sleep-5}.pl` are the capture-test
  programs.

No Python is used by project tooling. Python under `category/py-*`,
`lang/python` and `lang/node` remains upstream port content.

## Extracted Makefile helpers

Each helper is a POSIX `sh` script under the port's `files/` directory. The
Makefile keeps version variables, package lists and short install commands;
the helper owns loops, conditionals and path fan-out.

| Port | Helper | Responsibility |
| --- | --- | --- |
| `devel/codex` | `generate-completions.sh` | Generate bash/fish/zsh completions |
| `devel/fourmolu` | `cabal-inc.sh` | Update, bundle and atomically replace `cabal.inc` |
| `lang/node` | `link-npm-modules.sh` | Move npm modules and create symlinks |
| `net/i2pd` | `install-certificates.sh` | Install family/reseed certificates |
| `net/monero-lws` | `apply-monero-patches.sh` | Apply pinned Monero patches |
| `net/simplex-chat` | `post-patch.sh`, `check-package-paths.sh`, `cabal-inc.sh` | Dependency patches, package checks, cabal stages |
| `net/simplexmq` | `post-patch.sh`, `check-package-paths.sh`, `cabal-inc.sh` | Dependency patches, package checks, cabal stages |
| `sysutils/uutils/coreutils` | `locales.sh` | Link and install locale catalogs |
| `sysutils/uutils/findutils` | `prefix-binaries.sh` | Prefix installed tools with `uu-` |
| `sysutils/uutils/grep` | `prefix-binaries.sh` | Prefix installed tools with `uu-` |
| `sysutils/uutils/sed` | `prefix-binaries.sh` | Prefix installed tools with `uu-` |
| `x11/emwm-utils` | `install-cursors.sh` | Install cursor theme, preserving symlinks |
| `x11/fvwm3` | `rename-paths.sh` | Prefix FVWM3 manuals and commands |
| `x11/xfile` | `install-data.sh` | Install type maps, icons, examples and D-Bus service |

The simplex `cabal-inc` stages stay separate because they are maintainer-only
and depend on the generated manifest. Their command sequences moved to
`cabal-inc.sh`, while package/option data remains in the Makefile as the single
source of truth. The `do-test` targets retain their Cabal invocation because
they are test orchestration, not normal build recipes.

## Conventions

- No inline Perl or Python in shell, Makefiles or configuration.
- Use native shell for simple tests, loops over a few files, and short
  pipelines.
- Put reusable or multi-step operations in `files/*.sh`; use `set -eu`,
  quote paths, and guard unmatched globs with `[ -e ... ]`.
- Invoke helpers with `sh ${FILESDIR}/name.sh`; do not rely on the executable
  bit of a build-only helper.
- Pass path roots and command variables through the environment or arguments;
  do not hard-code the working directory.
- Keep Makefiles declarative: variables, dependency lists, targets and short
  commands. Do not replace a readable block with an unreadable one-liner.
- Do not duplicate data that Make already owns; version and patch lists stay
  in the Makefile, control flow moves to the helper.

## Verification

Performed statically and on the Unix host:

```sh
sh -n <changed shell helpers>
shellcheck -s sh <changed shell helpers>
perl -c devel/codex/files/openbsd-sandbox-{probe,regress}.pl
perl -c tools/t/*.t tools/t/fixtures/*.pl
prove -q tools/t/perl-tools.t
grep -R "perl -e\|python -c" --include="*.sh" --include="Makefile*" ...
```

Helper fixtures exercised prefixing, npm symlinks, locale linking/install,
FVWM3 renames, cursor symlinks, certificate copies, Monero patch application,
Codex completion generation, package-path checks, simplex post-patch, xfile
data installation, and `cabal-inc` build/test stages with stub tools.

A stub `bsd.port.mk` allowed `bmake -V COMMENT` to parse the changed
Makefiles; all changed ports parsed. The complete tree also parses except
`devel/crush` (needs a real `PROPERTIES` definition) and the
`sysutils/uutils` subdir Makefile (needs `bsd.port.subdir.mk`); neither was
touched by this refactor.

`shellcheck` is installed and reported no findings. `Perl::Critic` is not
installed in this environment. OpenBSD `make`, a real port build, package
creation, service tests and incremental-build checks were not run; those
remain outstanding.
