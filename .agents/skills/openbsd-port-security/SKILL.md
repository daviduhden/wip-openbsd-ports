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
   When the policy removes `proc` or `exec`, explicitly disable optional
   build-time features that fork or launch helpers; do not rely on configure
   defaults. A direct call blocked only by `pledge` may terminate the whole
   application instead of refusing the requested operation cleanly.
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
8. For browser-like clients, distinguish an in-process `pledge`/`unveil`
   policy from multi-process browser sandboxing. Map browser, renderer, GPU,
   utility, and helper processes separately; state which process each rule
   confines, and do not claim site isolation or renderer containment from a
   single-process policy. For a single-process client, claim only path,
   syscall, and external-execution confinement. Require HOME to resolve to an
   existing directory before deriving home-scoped rules. Prefer exact state
   files over a whole-HOME rule, skip `cwd` when it is HOME or an ancestor of
   HOME, refuse temp/save roots that cover HOME, and verify canonicalized
   directory roots do not escape their intended parent through symlinks. Guard
   path-prefix checks for `/` and shorter paths; never install a `/` rule.
   Disclose remaining writable roots such as `/tmp` and any loss of arbitrary
   local-file browsing.
9. For interactive clients whose configuration selects files and commands at
   runtime, map the configuration parser, included files, hooks, mailbox or
   workspace backends, caches, certificates, temporary files, and helper
   launch paths before proposing `unveil`. A fixed startup allowlist can break
   legitimate user-selected paths; a broad root rule may provide no useful
   filesystem boundary. If paths are opened after configuration or can change
   through commands, either add a reviewed path-registration design or state
   why a locked policy cannot preserve that behavior. For mail clients, audit
   IMAP/POP/SMTP, local mailbox formats, GPGME, Notmuch, SASL, and TLS
   separately. Libraries and helpers may open files, sockets, or processes
   outside the visible call site. User-configured editors, mailcap handlers,
   sendmail, tunnels, and shell escapes are an explicit execution boundary:
   `unveil` is removed on exec, so parent rules do not confine the helper.
   Check `pledge` child promises independently and do not describe them as
   filesystem containment. A pledged launcher can retain `proc` and `exec`
   while leaving `execpromises` unset; OpenBSD then starts executed children
   without pledge restrictions. Do not pass `NULL` after an earlier call has
   already set restrictive exec promises, because `NULL` preserves that
   existing policy.
10. Run positive and negative tests on an authorized isolated OpenBSD host: normal initialization and functionality, denied paths/network operations as applicable, child execution, failure handling, and reload/shutdown. Privileged installation, doas rules, service activation, kernel limits, and mount changes require explicit authorization. Use [openbsd-port-validation](../openbsd-port-validation/SKILL.md) to record build/package/runtime evidence separately.

### LibreSSL client and sandbox reviews

For TLS clients, check the target base LibreSSL headers and implementation
for each used API. Review peer-chain failure policy, DNS SAN precedence, IP
SAN handling, SNI, resource ownership and error paths. Keep explicit user
acceptance of an invalid certificate distinct from default policy; do not
turn a no-prompt/reject setting into acceptance. When `unveil` is locked,
allow only configured CA and client certificate/key files required by the
TLS path. For base OpenBSD LibreSSL, default trust paths are
`/etc/ssl/certs.pem` and `/etc/ssl/certs`; avoid unveiling `/etc/ssl`
wholesale when those exact paths suffice. Prefer a per-run, owner-only
temporary directory over granting all of `/tmp`; replace application
`tmpfile(3)` call sites that bypass the configured private temp root when
necessary. Require writable roots to be canonical directories owned by the
invoking user with private permissions, and refuse privileged execution
when the sandbox assumes an ordinary user. Do not widen `pledge` or claim
spawned-process confinement without verifying exec promises and inheritance
for the target OpenBSD release.

### NeoMutt static-path sandbox policy

For a fixed-path NeoMutt policy, apply `unveil` after resolving the
unprivileged user's home and before `mutt_init()` reads configuration or
`source` includes. Resolve HOME canonically, reject root and `/`, use a
private per-run temporary directory under HOME, and lock the rules. Keep
mail spool, DNS/password lookups, terminfo, CA files, package/system config,
SASL sockets/plugins and flavor-specific GPGME socket access explicit.
Document that startup and runtime paths outside the allowlist fail; do not
silently widen it to accommodate `-F`, `source`, mailboxes, caches,
certificates or attachments selected elsewhere.

When omitting pledge's `exec` promise, retain `proc` if the application
uses fork, wait, or kill outside helper execution. NeoMutt uses these for
process control and helper launch; with `proc`, an exec-denied child fails
without turning the parent's fork into a pledge violation. Document that
external commands cannot run. Apply and lock unveil before the final pledge
call; then omit the `unveil` promise too. Keep flavor-specific `unix` and
GPGME descriptor-passing promises only where the linked libraries need them.
Leave `execpromises` unset. Review pledge's exec behavior and unveil's
removal on exec before restoring external commands.

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
