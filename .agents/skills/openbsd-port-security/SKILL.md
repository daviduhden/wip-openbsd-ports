---
name: openbsd-port-security
description: Audit OpenBSD port security and compatibility when changing cryptography, sandboxing, privileged operations, service exposure, or platform-specific process behavior.
---

# Security and OpenBSD compatibility

Use for substantive security or platform audits, new privileged behavior, or changes to `pledge`, `unveil`, TLS, W^X, service users, and listener defaults. Routine metadata or PLIST edits do not require a complete security audit; use [openbsd-port-packaging](../openbsd-port-packaging/SKILL.md) for their packaging mechanics. This skill does not authorize system configuration changes or security testing against external services.

## Prerequisites

Read the selected port's Makefile, patches, configuration, `pkg/README`, `pkg/DESCR`, PLIST, and rc script together. Identify the target OpenBSD release/architecture and matching kernel manuals. Repository patches describe intended behavior; they are not proof that it works. Establish authorized test resources and retain the user's changes.

## Procedure

1. Map initialization, configuration loading, certificate/key reads, DNS, network listeners, inherited descriptors, fork/exec helpers, privilege changes, reload, and shutdown. Include optional features and negative paths. Inspect native APIs before replacing Linux-specific assumptions about procfs, signals, terminals, authentication, device ioctls, or shared libraries.
2. For LibreSSL, inspect actual API availability and return semantics. Do not identify OpenSSL 3 support solely through `OPENSSL_VERSION_NUMBER`; examine `LIBRESSL_VERSION_NUMBER` where relevant. Keep validation, authentication-tag checks, size conversions, and error handling intact. `net/i2pd` demonstrates backend guards and checked EVP operations; a build alone does not validate cryptographic behavior.
3. Use dedicated service accounts and minimal directory permissions appropriate to real state/key paths. Reconcile IDs with both `user.list` and the official `infrastructure/db/user.list`. Review listener addresses and authentication individually: confettysh exposes a public demonstration service by default, while soft-serve restricts selected endpoints. Keep secrets out of process arguments and logs.
4. Before proposing restrictions, study the syscall and process lifecycle. On an authorized OpenBSD test host, `trace_dir=$(mktemp -d /tmp/port-security.XXXXXXXX)` creates a private trace directory; then `ktrace -f "$trace_dir/trace" command arguments` and `kdump -f "$trace_dir/trace"` can help identify operations. Trace files may contain secrets, and traces cover only exercised behavior. Retain or remove the trace directory according to the authorized test plan. Do not trace production credentials or infer a complete policy from one startup run.
5. Apply native restrictions at the correct lifecycle point, check return values, and lock unveil rules when appropriate. Account for DNS, TLS, Unix sockets, logs, temporary files, key rotation, workers, and reload. Avoid broad promises just to silence failures. Verify the target kernel's exec and inheritance behavior: current `unveil(2)` documents removal of unveils on exec. A constrained launcher does not establish containment of an executed child. Filesystem visibility restrictions do not establish network, descriptor, process, or full syscall isolation.
6. Treat existing implementations separately. Tor's in-process profile rejects
   managed transports requiring exec. Codex's restricted command backend
   currently fails closed rather than claiming child containment; its
   regression exit 77 means unsupported, not success. Read current source and
   tests before updating these claims; never silently substitute an
   unrestricted profile. When managed network enforcement depends on a
   command sandbox, reject it before any native-launch shortcut and at both
   session creation and exec preparation so app-server and direct CLI paths
   cannot bypass the guard.
   For Codex updates, separately audit config loading, session creation,
   direct CLI execution, app-server/daemon execution, and PTY child launches.
   The current OpenBSD port has no native command sandbox: managed filesystem
   and network profiles must fail closed, while explicit `danger-full-access`
   runs with the invoking user's ordinary authority. An external sandbox is
   only declared by the user; Codex does not create or verify it. Keep daemon
   updates under `pkg_add` ownership, reject Codex self-update/replacement,
   and do not add a `sudo` dependency where the port uses OpenBSD tooling.
   Reconfirm each behavior against the selected release and tests before
   retaining these statements; do not infer `pledge`/`unveil` containment of
   executed children.
7. Examine executable memory requirements before adding `USE_WXNEEDED`. Codex/V8 is an existing exception requiring investigation, not a default for Rust or other ports. Do not weaken W^X globally or edit mounts/fstab automatically. Review privilege separation rather than applying setuid mechanically: emwm-utils uses setgid `auth`, drops the effective auth group before starting children, and reacquires it only around `auth_userokay(3)`; sudo-rs requires OpenPAM and has an explicitly unvalidated privilege path; VeraCrypt delegates a core helper through doas.
8. Run positive and negative tests on an authorized isolated OpenBSD host: normal initialization and functionality, denied paths/network operations as applicable, child execution, failure handling, and reload/shutdown. Privileged installation, doas rules, service activation, kernel limits, and mount changes require explicit authorization. Use [openbsd-port-validation](../openbsd-port-validation/SKILL.md) to record build/package/runtime evidence separately.

## Acceptance and diagnosis

Document the threat boundary, protected operations, unsupported configurations, target kernel, and exact tests. Every claim must match the process actually confined. Unsupported tests and skipped tests are not passes.

For failures, inspect checked syscall errors and, where authorized, trace the failing lifecycle stage. Distinguish unavailable APIs from denied operations, missing files from unveiled paths, and missing permissions from ownership/configuration errors. Validate privilege dropping and persistence permissions after restart. If a policy cannot preserve its stated restrictions, report the limitation and fail closed where the program promises confinement; do not advertise a complete sandbox.

## References

- [Porting security recommendations](https://www.openbsd.org/faq/ports/guide.html#Security).
- [pledge(2)](https://man.openbsd.org/pledge.2), [unveil(2)](https://man.openbsd.org/unveil.2), [ktrace(1)](https://man.openbsd.org/ktrace.1), and [kdump(1)](https://man.openbsd.org/kdump.1).
- [rc.subr(8)](https://man.openbsd.org/rc.subr.8) and [doas.conf(5)](https://man.openbsd.org/doas.conf.5).
- Repository behavior: `devel/codex/pkg/README`, `net/tor/pkg/DESCR`, `net/i2pd/patches/`, and `security/veracrypt/pkg/README`.

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
