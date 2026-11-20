---
name: openbsd-port-security
description: Audit OpenBSD port security and compatibility when changing cryptography, sandboxing, privileged operations, service exposure, or platform-specific process behavior.
---

# Security and OpenBSD compatibility

Use for substantive security or platform audits, new privileged behavior, or changes to `pledge`, `unveil`, TLS, W^X, service users, and listener defaults. Routine metadata or PLIST edits do not require a complete security audit; use [openbsd-port-packaging](../openbsd-port-packaging/SKILL.md) for their packaging mechanics. This skill does not authorize system configuration changes or security testing against external services.

## Prerequisites

Read the selected port's Makefile, patches, configuration, `pkg/README`, `pkg/DESCR`, PLIST, and rc script together. Identify the target OpenBSD release/architecture and matching kernel manuals. Repository patches describe intended behavior; they are not proof that it works. Establish authorized test resources and retain the user's changes.

## Procedure

Review client-triggered server startup separately from explicit service
startup. Missing keys or launch records must not silently select an insecure
mode. Require an explicit administrator choice, and check descriptor-repair
errors before installing hooks, parsing configuration or starting workers.

1. Map initialization, configuration loading, certificate/key reads, DNS, network listeners, inherited descriptors, fork/exec helpers, privilege changes, reload, and shutdown. Include optional features and negative paths. Inspect native APIs before replacing Linux-specific assumptions about procfs, signals, terminals, authentication, device ioctls, or shared libraries.
2. For LibreSSL, inspect actual API availability and return semantics. Do not identify OpenSSL 3 support solely through `OPENSSL_VERSION_NUMBER`; examine `LIBRESSL_VERSION_NUMBER` where relevant. Keep validation, authentication-tag checks, size conversions, and error handling intact. `net/i2pd` demonstrates backend guards and checked EVP operations; a build alone does not validate cryptographic behavior.
3. Use dedicated service accounts and minimal directory permissions appropriate to real state/key paths. Reconcile IDs with both `user.list` and the official `infrastructure/db/user.list`. Review listener addresses and authentication individually: confettysh is an unauthenticated demonstration whose packaged defaults bind loopback, while soft-serve restricts selected endpoints. Keep secrets out of process arguments and logs.
4. Before proposing restrictions, study the syscall and process lifecycle. On an authorized OpenBSD test host, `trace_dir=$(mktemp -d /tmp/port-security.XXXXXXXX)` creates a private trace directory; then `ktrace -f "$trace_dir/trace" command arguments` and `kdump -f "$trace_dir/trace"` can help identify operations. Trace files may contain secrets, and traces cover only exercised behavior. Retain or remove the trace directory according to the authorized test plan. Do not trace production credentials or infer a complete policy from one startup run.
5. Apply native restrictions at the correct lifecycle point, check return values, and lock unveil rules when appropriate. Account for DNS, TLS, Unix sockets, logs, temporary files, key rotation, workers, and reload. Avoid broad promises just to silence failures. Verify fork/exec inheritance against the exact target source as described below; a constrained launcher alone does not establish containment of an executed child. Filesystem visibility restrictions do not establish network, descriptor, process, or full syscall isolation.
   When the policy removes `proc` or `exec`, explicitly disable optional
   build-time features that fork or launch helpers; do not rely on configure
   defaults. A direct call blocked only by `pledge` may terminate the whole
   application instead of refusing the requested operation cleanly.

   Do not add pledge's `exec` or `error` promises to a new policy, including
   through `execpromises`. Reconstruct every promise string and its
   compile-time conditions, not just the visible literal. If an existing
   policy uses either promise, determine which operation needs it and either
   remove that operation, move it before the policy is installed, or split
   the work into a helper with its own reviewed boundary. `proc` permits
   fork/wait/kill but not execution; retaining it does not make a child run.
   If no exec-free design preserves the documented behavior, state the
   limitation and leave the hardening incomplete instead of granting
   execution. A helper that can run arbitrary commands must not be presented
   as containment for the restricted process.
6. Treat existing implementations separately. Tor's in-process profile rejects
   managed transports requiring exec. Codex's restricted command backend
   currently fails closed rather than claiming child containment; its
   regression exit 77 means unsupported, not success. Read current source and
   tests before updating these claims; never silently substitute an
   unrestricted profile. When managed network enforcement depends on a
   command sandbox, reject it before any native-launch shortcut and at both
   session creation and exec preparation so app-server and direct CLI paths
   cannot bypass the guard.
   Keep the Codex regression harness aligned with that missing-backend
   behavior: test both named and built-in managed profiles, including
   network-enabled profiles, require the actual backend-refusal diagnostic
   and verify that a child marker was not created. Use the same child in an
   explicit full-access control. Timeout, signal, command-not-found and
   harness setup failures do not prove rejection. Retire old positive
   confinement/compiler cases when no supported sandbox can execute them;
   successful refusal checks still return 77 for unsupported OS isolation.
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
7. Examine executable memory requirements before adding `USE_WXNEEDED`.
   OpenBSD rejects a mapping that requests `PROT_WRITE|PROT_EXEC` at the same
   time; it does not reject an RW mapping that is later changed to RX, and
   such a secure-JIT path needs neither `USE_WXNEEDED` nor a `wxallowed`
   mount. Add `USE_WXNEEDED` only when a component genuinely requires a
   simultaneous writable and executable mapping and no secure transition is
   available. RandomX enables `RANDOMX_FLAG_SECURE` on OpenBSD through
   `jit_compiler.hpp`, so do not add the flag pre-emptively. Codex uses a
   reviewed interpreter-only production path on OpenBSD;
   recheck allocator and explicit JIT-enable reachability before restoring
   executable-memory exceptions or changing V8 inputs. Do not weaken W^X
   globally or edit mounts/fstab automatically.
   Review privilege separation rather than applying setuid mechanically:
   emwm-utils uses setgid `auth`, drops the effective auth group before
   starting children, and reacquires it only around `auth_userokay(3)`;
   sudo-rs requires OpenPAM and has an explicitly unvalidated privilege path;
   VeraCrypt delegates a core helper through doas.
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
   trace the target kernel's conditional unveil inheritance rather than
   assuming that all parent rules survive or disappear. Check `pledge` child
   promises independently and do not describe them as filesystem containment.
   A launcher that retains `exec` with unset
   `execpromises` lets OpenBSD start executed children without pledge
   restrictions; do not treat that as containment and do not add it in new
   work. Do not pass `NULL` after an earlier call has already set restrictive
   exec promises, because `NULL` preserves that existing policy.
10. Run positive and negative tests on an authorized isolated OpenBSD host: normal initialization and functionality, denied paths/network operations as applicable, child execution, failure handling, and reload/shutdown. Privileged installation, doas rules, service activation, kernel limits, and mount changes require explicit authorization. Use [openbsd-port-validation](../openbsd-port-validation/SKILL.md) to record build/package/runtime evidence separately.

### LibreSSL client and sandbox reviews

For TLS clients, check the target base LibreSSL headers and implementation
for each used API. Review peer-chain failure policy, DNS SAN precedence, IP
SAN handling, SNI, resource ownership and error paths. Keep explicit user
acceptance of an invalid certificate distinct from default policy; do not
turn a no-prompt/reject setting into acceptance. When `unveil` is locked,
allow only configured CA and client certificate/key files required by the
TLS path. For base OpenBSD LibreSSL, the default trust file is
`/etc/ssl/cert.pem`; `/etc/ssl/certs` and the legacy `certs.pem` name may
also be needed for compatibility. Avoid unveiling `/etc/ssl` wholesale when
those exact paths suffice. Prefer a per-run, owner-only
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
external commands cannot run, including the default `/usr/sbin/sendmail`
transport and PGP/S/MIME helpers; built-in SMTP remains usable. Apply and
lock unveil before the final pledge call, then omit the `unveil` promise too.
Keep flavor-specific `unix` only where a linked library opens a Unix socket.
Do not grant `sendfd`/`recvfd` unless a sendmsg/recvmsg or explicit
descriptor-passing call site exists; NeoMutt has none. Leave
`execpromises` unset. Review pledge's exec behavior and the target kernel's
conditional unveil inheritance before considering external commands; the
ban on new `exec` and `error` promises still applies.

### Target-specific process inheritance

Pin the target OpenBSD source revision as well as the ports revision. Read
the matching manuals and `sys/kern/kern_fork.c`, `kern_exec.c`,
`kern_pledge.c`, `kern_unveil.c`, and the copied process flags. A live manual
page or an earlier audit may describe another kernel's behavior.

In the reviewed current kernel, fork copies the pledge and unveil state.
At exec, `PS_EXECPLEDGE` selects the branch retaining unveil and applying
the recorded exec promises; without that flag, exec clears pledge and
destroys unveil. A successful call with a non-NULL exec-promises argument
establishes that flag; NULL preserves an earlier setting. Reconstruct the
entire call history, not only the last call. Recheck these branches and never
infer child confinement from the parent's rules alone. This is an
inheritance check, not permission to introduce `exec` or `error`.

For an early standalone-command policy, include the runtime and toolchain
startup paths. For example, Rust's `current_exe()` may use a process sysctl
on an older toolchain but `getexecpath()` on the reviewed OpenBSD toolchain.
Constrain the build dependency when the policy depends on that change;
do not widen promises to hide an unreviewed runtime requirement. Keep
process-wide restrictions out of reusable library entry points. Account
for inherited descriptors when stating filesystem or network guarantees.

## Collection-wide static audit procedure

Before authoring changes, build an individual inventory for every maintained
port: version, languages, build system, direct and vendored dependencies,
actual crypto backend, patches, customizations, privileged operations and
existing sandbox. Inventory multicall applets and independently installed
subports as separate execution paths. Rank exposure to order the work, never
to exclude a port. Preserve versions during a security-only audit.

Use `mktemp -d` with separate original, official-patched, local-patched,
development, sandbox, regenerated-patch, report and final-result trees.
Retain exact distfiles and pinned dependency inputs for three-way comparison.
Compare official `-current` patches with the matching official source version;
a failing patch against a different version is not evidence of obsolescence.
Assign disjoint author scopes and independent reviews for crypto, W^X,
syscalls, libc/toolchains, pledge, unveil, IPC, process execution and ports
integration. Cover unchanged ports in the second review too. Integrate only
statically justified, independently reviewed changes after checking the
current destination against the saved worktree baseline. Preserve conflicts
for investigation rather than overwriting concurrent work.

Trace every policy string, configuration override and `execpromises` value.
Reject forbidden promises before installing a user-configurable policy;
check embedded NULs and failed string conversion in language bindings so
`pledge(NULL, NULL)` cannot masquerade as successful restriction. A generic
policy-binding API is not an installed application policy; trace its concrete
callers before changing supported arguments. Never add
`exec` or `error`. If a correct execution-free boundary cannot preserve
functionality, retain the existing implementation, name the blocker and mark
hardening incomplete. A general command broker is not privilege separation.

For document workers, dispatch before configuration, credentials and async
runtime initialization. Close inherited descriptors with checked native
semantics, minimize inherited environment, canonicalize and validate exact
inputs, lock unveil and check pledge failure. Bound and drain worker output
before decoding IPC; audit timeouts, child groups and error cleanup. Describe
which worker is confined and which supervisor or explicit helper override
remains trusted. Do not describe CPU limits or timeouts as memory limits.
For library ports, do not install a process-wide policy on the embedding host.

Check certificate-chain and identity verification separately, including
HTTP fallbacks and command-line download retries. Treat explicit SPKI pins
as a separately reviewed authentication mechanism. TLS configuration setter
failure must propagate with correct ownership cleanup. Never accept a failed
TOFU persistence write as a successful authenticated connection. Protect
credential files before truncating or writing, check persistence errors and
avoid replacing an unreadable existing identity with a new one.

An explicitly configured CA, client certificate or key path must fail
closed when unreadable or absent; never discard it and silently select
built-in trust roots or another identity. Review Python and native HTTP
backends separately. Keep an explicit verification-disable override
distinct from default policy. A malformed nonempty PIN must likewise
remain an error, not become an absent PIN or select another authentication
method through a failed string conversion.

Loopback binding is not authentication. A browser can submit requests to
local tool servers or exploit DNS rebinding. Before reading request bodies
or dispatching tools, validate the configured local Host authority, Origin,
fetch metadata and required media type. State the remaining local-user and
explicit remote-listener authority; do not call request guards a sandbox.

Check reentrant callbacks before retrying native TLS operations. Own the
pending buffer and request, establish asynchronous completion state, and
retain the object before scheduling a cycle that can destroy or replace
the TLS connection. Audit cancellation and error paths as well as success.
Apply canonical ancestor checks to every unveil directory source, including
default support directories and symlinks, not only cwd and user overrides.
Create temporary fixture files exclusively and private directories
atomically; predictable names must not allow truncating an existing file
or following an attacker-created directory. Static changes to test sources
do not constitute permission to execute tests.

For concurrent subprocess capture, waiting for the direct child does not
join independently spawned pipe or PTY reader tasks. Synchronize every
shared buffer write and read, including buffers used by multiple streams,
and copy snapshots while holding the lock. Do not expose backing slices
after unlocking. An unbounded reader join can hang when descendants keep
a PTY open; distinguish race removal from complete output capture and
descendant cleanup.

When disabling a JIT to preserve W^X, establish all installed entry points,
explicit enable paths, WebAssembly exposure and allocator reachability before
removing `USE_WXNEEDED`. Distinguish reservation maximum permissions from
active RWX mappings. Document interpreter performance effects and defer ELF
and kernel behavior to native validation. Do not copy this conclusion to a
full-featured runtime with reachable JIT paths. An extracted header patch
also does not fix an untouched archive installed for downstream consumers;
trace the actual packaged input and generated configuration.

Trace executable-memory linker flags through the actual producer of each
binary, including build auxiliaries. A GN-built helper can receive wxneeded
without forwarding that option through an ar-built library to its Rust
executable. Inspect archive commands and Cargo-emitted link directives;
do not infer final flags from the archive type alone.
Conversely, a full JIT runtime can reach an RWX code-range initialization
even when a different builtins path uses RW-to-RX. Record both call paths
and defer final ELF and kernel behavior to native validation.

The final Markdown report must contain every port in a crypto/W^X/syscall/
sandbox/patch matrix, individual compatibility and security findings, patch
and official-change dispositions, preserved customizations, integration
status and prioritized native checks. Record previous `exec`/`error` usage,
removed promises, helper authority and remaining architecture blockers.
Distinguish static compatibility, static corrections, partial implementation,
design proposals, incompatibility and pending investigation. Never present
an unimplemented design or a static review as a functioning sandbox.

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
consistency, validate local references, and run `perl scripts/validate-agent-knowledge.pl --scope worktree` after instruction edits. The automated check covers
structure and change presence; a person must still judge whether the update is
relevant. Include the synchronization result in the final report.
