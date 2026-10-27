---
name: openbsd-port-packaging
description: Package an OpenBSD port correctly, including PLIST annotations, DESCR and README, samples, users and groups, rc.d services, permissions, shared libraries, and installed-file auditing.
---

# Package an OpenBSD port

Use this skill for `pkg/PLIST*`, `pkg/DESCR*`, `pkg/README`, `pkg/MESSAGE`,
`@sample`, `@newuser`/`@newgroup`, `@rcscript`, file modes, and installed-file
layout. For the initial build use [openbsd-port-validation](../openbsd-port-validation/SKILL.md);
for a substantive privilege or sandbox review use
[openbsd-port-security](../openbsd-port-security/SKILL.md). Routine metadata
edits do not require a security audit.

## Prerequisites

Read the Makefile, `pkg/` contents, the fake tree, and the upstream
configuration and service documentation together. Confirm the target OpenBSD
release, the selected `MULTI_PACKAGES` / flavor, and the account namespace in
the official `infrastructure/db/user.list`. Inspect uncommitted changes before
regenerating a PLIST. Packaging changes still require a real `make fake` and
`make package` on OpenBSD to be considered validated.

## Procedure

1. Review `COMMENT` (short, no package name, no trailing period), `pkg/DESCR`
   (one to a few paragraphs), and `pkg/README` (operational instructions shown
   after installation). Document initialization, configuration, account,
   service, and migration steps that are not obvious. Do not put secrets or
   host-specific values in a sample.
2. Run `make fake` and inspect `WRKINST` before trusting a packing list. Then:

   ```sh
   make update-plist
   ```

   `update-plist` proposes `pkg/PLIST` or `pkg/PLIST-*`; it does not prove the
   layout is correct. Review added, removed, and mode/owner changes, and compare
   the fake tree with the resulting list. Do not hand-edit a generated list
   when the target can regenerate it.

3. Use the correct annotations:
   - `@bin` for executables, `@man` for manual pages, `@static-lib` for static
     libraries, and the normal path syntax for data and documentation.
   - `@sample` for configuration and state paths that must not overwrite a
     user's existing file or directory. Verify the packaged path and the
     runtime path are the same; a mismatch leaves the service unable to start.
   - `@mode`, `@owner`, and `@group` apply to following entries. Reset them
     with bare `@mode`, `@owner`, and `@group`; otherwise later files inherit
     unintended ownership.
   - `@rcscript ${RCDIR}/name` for each installed service script. The installed
     basename must match the script and should avoid characters unsuitable for
     rc.d names; dashes are commonly replaced with underscores.
   - `@newuser` / `@newgroup` for dedicated accounts. Use a fixed free ID from
     the official registry, the same ID for a user/group pair, a non-login shell,
     and a home/state path that the package actually creates.
4. For `MULTI_PACKAGES`, keep `COMMENT-*`, `DESCR-*`, `PLIST-*`, and `-*`
   dependency variables consistent. Do not flatten subpackages into one PLIST
   or make `-main` depend on an optional GUI package. Check exact subpackage
   dependencies such as `${BASE_PKGPATH},-main=${VERSION}`.
5. Design the service lifecycle. A typical rc.d script defines `daemon`,
   `daemon_flags`, `daemon_user`, `daemon_logger`, optionally
   `daemon_execdir`/`daemon_timeout`, sources `/etc/rc.d/rc.subr`, sets
   `rc_bg` and `rc_reload` only when the daemon actually needs them, and ends
   with `rc_cmd "$1"`. Use `rc_exec` for environment assignments because `su`
   may reset the environment. Do not add `&`, shell redirections, or a manual
   PID file to imitate backgrounding; use `rc_bg`.
6. Verify owners, modes, and writability from the service's perspective:
   configuration under `/etc` is normally root-owned and readable by the
   service group (for example `0640`); private state and keys are not
   world-readable; state directories are not daemon-owned if the daemon could
   then replace its own configuration. Check persistent paths, log paths, and
   any directory the service expects but the package does not create.
7. Check native linkage. `WANTLIB` describes libraries the binary needs;
   `LIB_DEPENDS` names the packages that provide them. Run:

   ```sh
   make port-lib-depends-check
   ```

   Add missing entries and remove stale ones. `dlopen(3)` libraries are not
   detected automatically, so document and test them separately.
8. Install the package on an authorized test host, inspect `pkg_info -L`, and
   exercise the service or program. Test a fresh install and, where relevant,
   an upgrade over an existing configuration. Verify that `@sample` does not
   overwrite user data and that `pkg_delete` does not remove user-created state.
9. Finish [openbsd-port-validation](../openbsd-port-validation/SKILL.md).
   Record which packaging and runtime checks were actually run.

## Checks and acceptance

- Every installed file is registered exactly once, with the correct package
  and annotations; no build product or generated-at-install file is missing.
- `DESCR`, `COMMENT`, `README`, and service instructions agree with the
  installed paths and account.
- Samples are usable, do not contain secrets, and do not overwrite existing
  configuration.
- Account IDs and names are unique against the official registry; the state
  and home directories exist with intended ownership and modes.
- rc.d scripts start, stop, and reload the real daemon as the intended user;
  `rcctl check` and logs support the claim.
- `port-lib-depends-check` and `make package` pass, and the package installs
  and removes cleanly.

## Common failures

- **PLIST says `/var/foo`, rc.d uses `/var/db/foo`:** reconcile the paths and
  create the directory the daemon actually uses. A `@sample` line for the wrong
  directory does not create the right one.
- **A secret is installed `0644`:** set a restrictive mode and group; do not
  rely on the daemon's umask or on `--config-file` hiding the value from the
  process list.
- **A daemon owns its configuration directory:** a compromised daemon can
  replace its own config and restart with different privileges. Keep config
  root-controlled and grant only read access.
- **`@sample` overwrites a user file:** re-read the annotation and the
  installation path; test an upgrade, not only a fresh install.
- **A service binds all interfaces unexpectedly:** inspect defaults and the
  README. Do not describe a demonstration or unauthenticated listener as
  localhost-only.
- **The package contains an unregistered generated file:** fix `do-install` or
  the PLIST; do not hide the difference with a broad directory entry.

## References

- [OpenBSD porting guide](https://www.openbsd.org/faq/ports/guide.html)
- [pkg_create(1)](https://man.openbsd.org/pkg_create.1),
  [pkg_add(1)](https://man.openbsd.org/pkg_add.1),
  [rc.subr(8)](https://man.openbsd.org/rc.subr.8),
  [rcctl(8)](https://man.openbsd.org/rcctl.8)
- [packages(7)](https://man.openbsd.org/packages.7),
  [useradd(8)](https://man.openbsd.org/useradd.8)
- Repository: `net/simplexmq/pkg/`, `net/tor/pkg/`, `net/i2pd/pkg/`, and
  `games/assaultcube/pkg/` show working annotations and subpackages.

## Maintenance & Continuous Learning

When this skill is used to modify the repository, review this skill after the
work. Update it when procedures, tools, configurations, project behavior, or
assumptions have changed, and add reusable knowledge that improves future use.
Correct instructions that proved wrong; keep examples and validation commands
current, and remove obsolete or duplicated guidance. Do not record one-off
execution details. Review linked skills and applicable `AGENTS.md` files for
consistency, validate local references, and run `perl tools/check-agent-sync.pl` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
