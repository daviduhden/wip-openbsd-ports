# OpenBSD sandbox backend for Codex

This document describes the OpenBSD `pledge(2)`/`unveil(2)` sandbox backend
added to the packaged Codex source. It is written for maintainers of the port.

**Status: initial implementation, statically validated only.** No part of this
backend has been executed against an OpenBSD kernel yet. Every guarantee below
is marked either *statically implemented* (reviewable in the source and covered
by unit tests that run anywhere) or *unverified* (requires a native OpenBSD
build and kernel tests). Nothing here should be presented as runtime-verified.

## 1. Dependency

The backend binds the OpenBSD kernel interfaces through the `rust-openbsd`
crate (import name `rust_openbsd`), pinned in the port to the immutable commit

    rust-openbsd 24f45496473ddbde171f1ba97897c2470ac26fed (0.2.0)

fetched with `DIST_TUPLE` into `${WRKDIST}/rust-openbsd` and consumed as a path
dependency (`rust-openbsd = { path = "../rust-openbsd" }`). It is declared only
for `cfg(target_os = "openbsd")` in `codex-rs/sandboxing/Cargo.toml`, so no
other platform gains the dependency. The crate has no dependencies of its own,
so `crates.inc` is unchanged.

The backend enables the crate's `openbsd-8-0` feature, which adds
`getexecpath(3)`; the symbol first appeared in OpenBSD 8.0, so **the port
requires OpenBSD 8.0 or later**. That is what the port targets: the patches are
written for the `-current` tree that 8.0 is cut from.

Only the public API of `rust-openbsd` is used: `pledge_both`, `unveil`,
`lock_unveil`, `Promises`, `Promise`, `Permissions`, `Permission`, and
`execpath`. There are no duplicated FFI declarations and no direct `libc` use
for pledge or unveil in the backend.

## 2. Where the code lives

| File | Purpose |
| --- | --- |
| `codex-rs/sandboxing/src/openbsd_policy.rs` | Platform-independent policy translation (compiled and unit tested on every host) |
| `codex-rs/sandboxing/src/openbsd.rs` | OpenBSD-only helper: argument construction, validation, unveil/pledge application, `execve` |
| `codex-rs/sandboxing/src/manager.rs` | Backend selection and command transformation |
| `codex-rs/protocol/src/sandbox.rs` | `SandboxType::OpenBsdPledgeUnveil` |
| `codex-rs/exec-server-protocol/src/protocol.rs` | `ProcessSandboxType::OpenBsdPledgeUnveil` |
| `codex-rs/arg0/src/lib.rs` | `codex-openbsd-sandbox` arg0 dispatch and PATH alias |

## 3. Backend selection

`get_platform_sandbox()` returns `Some(SandboxType::OpenBsdPledgeUnveil)` when
the target is OpenBSD. Selection otherwise follows the existing rules: a
`danger-full-access` profile, an explicitly forbidden sandbox, or an approved
escalation never selects a backend, so OpenBSD is not treated as an unsupported
Unix fallback once the backend is available.

## 4. Command launch mechanism

Codex never restricts the controller process. A sandboxed command is launched
through a helper that is the *same* Codex executable, re-invoked under the arg0
alias `codex-openbsd-sandbox`:

* `arg0` populates a private PATH directory with a `codex-openbsd-sandbox`
  symlink to the Codex executable.
* `SandboxManager::transform` rewrites the command to
  `argv = [codex, --command-cwd <cwd>, --openbsd-policy <json>, --, <command...>]`
  and sets `arg0 = Some("codex-openbsd-sandbox")`.
* The helper executable path is the path of the running Codex binary. The
  controller resolves it with `getexecpath(3)` (via the bindings' `execpath`),
  which returns the canonical, absolute pathname of the executable.
  `std::env::current_exe()` is *not* used: Rust documents it as best-effort on
  OpenBSD, where it reports `argv[0]` and returns a bare program name when Codex
  was found through `PATH`. An unresolved name would let the spawn layer search
  `PATH` for the helper, so a failure to resolve the path is fatal instead.
* The spawn layer applies `arg0` as `argv[0]`, so `codex-arg0` dispatches to
  `codex_sandboxing::openbsd::run_openbsd_sandbox_main()`.
* The helper applies the policy to itself and `execve(2)`s the target.

This uses the existing single-executable packing in `Makefile`/`PLIST`: no new
installed binary is required.

### Why a helper process

The helper is created by `execve(2)` from the controller; it is never a
`fork(2)` child of a multithreaded process. It therefore performs its whole
security transition in a fresh, single-threaded address space. This matters
because reducing a *multithreaded* process to a restrictive promise set makes
the OpenBSD kernel unwind sibling threads while cleaning up unveil state, and
the resumed threads then execute system calls the new restriction forbids. The
helper avoids that class of failure entirely.

## 5. Order of operations

1. Parse and validate the command line and the serialized policy.
2. `chdir(2)` into the command working directory, before any restriction.
3. Install every `unveil(2)` rule.
4. Lock the unveil configuration (`unveil(NULL, NULL)`); this is irreversible.
5. A single `pledge(promises, execpromises)` call.
6. `execve(2)` the target program.

Step 5 relies on the explicit `execpromises` argument. A successful `pledge(2)`
in the helper does **not** by itself restrict the executed program: the
promises granted to the target are the second argument, which is why the
backend always sets it. The helper's own current promises include `exec` (a
path promise) so that the kernel does not discard the unveil state as the
helper transitions, and they are deliberately *not* taken from the policy, so a
malformed policy cannot widen the helper.

## 6. Policy translation

`translate_permission_profile` maps a Codex `PermissionProfile` to an
`OpenBsdSandboxPolicy { restrict_filesystem, writable, network, rules }`.

`unveil(2)` is a whitelist with deepest-match semantics (see `unveil(2)`: a
directory grants access to everything below it "if and only if no more specific
matching unveil exists at a lower level"). The two profile shapes Codex
produces are therefore representable exactly:

* **read-only** — `unveil("/", r x)`;
* **workspace-write** — `unveil("/", r x)`, then each writable root with
  `r w c x`, then the root's protected descendants (`.git`, `.agents`,
  `.codex`, `.aws`, and the profile's read-only subpaths) back to `r x`.

Filesystem handling:

| Concept | Mapping |
| --- | --- |
| Readable roots | `unveil(path, r x)` |
| Writable roots | `unveil(path, r w c x)` |
| Protected / read-only subpaths under a writable root | `unveil(path, r x)` (shadowing) |
| Denied-read roots | `unveil(path, "")` (no permissions) |
| Denied-read globs | **unsupported** → fail closed |
| Arbitrary narrow read set | **unsupported** → fail closed |

Paths are resolved by Codex against the policy working directory before they are
serialized, so the helper receives absolute paths only and re-validates that.

`unrestricted` and `external-sandbox` filesystem kinds add no unveil rules (and
do not call `unveil(2)` at all), because those profiles do not ask Codex to
build a filesystem sandbox. `network` is carried through independently.

Symlinks, missing paths, non-UTF-8 names, and temporaries are handled by the
kernel's normal `unveil(2)` semantics: a directory is remembered at the time of
the call, a non-directory final component is remembered by name, and a missing
intermediate directory makes the rule fail with `ENOENT`, which fails the
launch closed. None of this has been exercised on a kernel yet.

## 7. Promise selection

The execution promise set is explicit and auditable; `Promises::ALL` is never
used and there is no promise-learning mechanism.

Always granted: `stdio`, `rpath`, `prot_exec`, `exec`, `proc`, `tty`.

* `stdio` — descriptors, memory, timers, process attributes.
* `rpath` — reading files, and the dynamic loader resolving libraries.
* `prot_exec` — the loader maps shared objects executable.
* `exec`, `proc` — `/bin/sh`, `make`, `cargo`, `rustc` and `clang` fork,
  execute, and signal subprocesses.
* `tty` — interactive shells use terminal ioctls.

Granted only when the policy grants writes: `wpath`, `cpath`, `flock`
(`flock` is required by build tools such as `cargo` for their lock files).

Granted only when the policy enables the network: `inet`, `dns`.

Deliberately never granted: `unix`, `fattr`, `chown`, `dpath`, `getpw`,
`settime`, `error`, and everything else. In particular the `error` promise is
not granted, so a violation aborts the process rather than being converted to
`ENOSYS`, and promise increases cannot be silently ignored.

**Known limitation (unverified).** A fixed set cannot be correct for every
arbitrary user command. Commands that need an omitted promise (for example an
AF_UNIX socket, a metadata change, or a device `ioctl`) fail closed — the
process aborts. Whether the base set is sufficient for common `cargo`/`rustc`/
`clang`/`make`/shell workloads must be established by kernel testing.

## 8. Network limitations

Codex's network setting is a boolean. `pledge(2)` can either grant `inet`
(arbitrary outbound connections) or withhold it (no sockets), so:

* network enabled → `inet` and `dns` are granted;
* network restricted → they are not.

There is no destination-, port-, or domain-based filtering, and the backend
does not claim any. When the caller requires all egress to go through the
managed network proxy **and** the policy restricts the network, translation
fails with an explicit unsupported-policy error instead of silently granting
unrestricted connectivity.

## 9. Unsupported policies (fail closed)

The following return `OpenBsdPolicyError::Unsupported` and the command is not
executed:

* a restricted filesystem policy that does not grant full-disk read (an
  arbitrary read set cannot be expressed as an `unveil(2)` whitelist);
* glob-based read denials;
* a managed network proxy over a restricted network policy.

A sandbox preparation failure is never converted into running the command
outside the sandbox.

## 10. Approval and escalation

The backend is selected at the same point as the other platform backends and
does not change approval handling. An approved escalation or explicit bypass
selects no backend (`SandboxType::None`), exactly as elsewhere. Denied requests,
retry behaviour, and restricted escalation are untouched. A failed sandbox
setup surfaces as an error (`SandboxTransformError::OpenBsdPreparation`,
`MissingOpenBsdSandboxExecutable`) and does not trigger an unsandboxed retry.

Denial classification: `SandboxViolationBackend::OpenBsdPledgeUnveil` is
reported when a sandboxed command failure is classified as a denial. The
classification deliberately uses the existing output-keyword heuristic only;
a `SIGABRT` is **not** treated as proof of a pledge violation, because ordinary
program failures can also abort. `unveil(2)` denials surface as `EACCES`/
`ENOENT` and are not distinguishable from an ordinary permission error without
kernel evidence.

## 11. Security assumptions requiring kernel verification

* Deepest-match `unveil(2)` shadowing really does revoke write access for
  protected descendants under a writable root.
* Revoking read access for a denied path under an unveiled `/` works, and does
  not remove the ability to `execve` the target.
* The helper's current promise set preserves the unveil configuration across
  its own `pledge(2)` call, and the execution promise set is what the target
  receives.
* The chosen base promise set is sufficient for the sandboxed `cargo`/`rustc`/
  `clang`/`make`/shell workloads.
* Installing `unveil(2)` rules succeeds for the paths a restricted profile
  produces (the caller must be able to access each path at rule-installation
  time).

## 12. Validation performed so far

Static/analytical validation that has actually been executed:

* Every port patch applies with `patch -p0 -F0`, without fuzz and without
  offset, both individually and as a complete set. The `modcargo-crates` patches
  need the cargo module's vendored tree and are outside this check.
* The OpenBSD-gated Rust code is type-checked on a Linux host with a
  `RUSTC_WRAPPER` that adds `--cfg target_os="openbsd"` to `rust_openbsd` and to
  the Codex crates that contain OpenBSD arms (`codex-sandboxing`, `codex-arg0`,
  `codex-exec-server`); every other crate keeps the host target, so crates such
  as `mio` still compile against the host's libc layout:
  * `cargo check -p codex-sandboxing --tests` — succeeded, which compiles
    `openbsd.rs`, `openbsd_policy.rs` and the `manager.rs` arm that calls
    `getexecpath(3)` through the bindings;
  * `cargo check -p codex-arg0 -p codex-exec-server` — succeeded;
  * `cargo check -p codex-exec-server --tests` — succeeded.
  Negative control: with the `openbsd-8-0` feature disabled, the same check
  fails with `cannot find function execpath in crate rust_openbsd`, which shows
  that the backend arm under test is really being compiled.
* `cargo test -p codex-sandboxing openbsd` — 13/13 unit tests passed. The policy
  translation, validation, and helper argument construction are pure logic and
  were executed for real; `openbsd_policy.rs` is unchanged since that run.
* The regenerated `manager.rs` patch is rustfmt-clean (formatted with the
  workspace's `rustfmt.toml`).
* `distinfo` entries for the new `DIST_TUPLE` were derived from the archive
  GitHub serves; the method reproduces the previous entry's hash and size
  exactly.

Not executed (and therefore unverified): anything that needs the OpenBSD
kernel, and any build with the real OpenBSD target, including the libc symbols
the bindings link against.

## 13. Remaining work

1. Build the port on OpenBSD 8.0/current for `x86_64` and `aarch64`; the
   OpenBSD-gated code has only been type-checked on a Linux host, never
   compiled or linked with the real target.
2. Run the unit tests in `openbsd_policy.rs` on the target.
3. Kernel tests: execute a sandboxed command under each supported policy and
   confirm the intended writes succeed, the unintended writes fail, the
   network setting is honoured, and protected metadata stays read-only.
4. Kernel tests for the unsupported cases: confirm they fail before execution.
5. Kernel tests for the promise set: `cargo`, `rustc`, `clang`, `make`, and a
   shell under `workspace-write`, and the same under `read-only`.
6. Only after the above pass should the backend be enabled by default (it is
   currently selected whenever OpenBSD builds select a platform sandbox, which
   is the same condition as the other platforms).

## 14. Divergences from the port in `-current`

This port carries changes that `-current`'s `devel/codex` does not, and omits
some of its patches. The reasons, so that a future sync does not lose them:

* `DIST_TUPLE` names the rust-sdk checkout `./rust-sdk` (upstream's own
  `Cargo.toml` refers to `../../rust-sdk/crates/rmcp`) where `-current` uses
  `./rmcp`, and fetches crossterm from `openai-oss-forks` where `-current` uses
  `nornagon`. Both are the same commits (`3e636cab…`, `ed1cdab3…`) and the port
  is internally consistent: the Makefile, `distinfo` and
  `patch-codex-rs_Cargo_toml` all use the same names.
* `patch-codex-rs_Cargo_toml` also adds the `rust-openbsd` workspace dependency,
  so `codex-rs/Cargo.toml` has a single patch (update-patches keys patches by
  the file they modify; two patches for one file collide).
* The v8/aws-lc patch set differs: this port configures partition_alloc through
  `PA_BUILDFLAG(IS_BSD)` plus its own libunwind/gn patches, while `-current`
  patches `partition_alloc_forward.h` and `spinning_mutex.cc` for an
  `OS_OPENBSD` futex. Both target the same subsystem without overlapping files;
  the two `-current` patches were not adopted because this port's v8 patches
  already select the BSD platform configuration.
* `-current`'s `patch-codex-rs_features_src_lib_rs` sets
  `default_enabled: false` for the `daemon_auto_start` feature. **Do not adopt
  it here:** this port's daemon integration relies on that feature being
  enabled (`pkg/README`, `daemon-integration.md`).
* `-current`'s `patch-codex-rs_chatgpt_src_lib_rs` adds a second
  `#![recursion_limit]` attribute; it applies cleanly here but is not needed,
  because it works around an interaction that this port's patch set does not
  have.
