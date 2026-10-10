# Codex daemon provided by the OpenBSD package

**ENABLED_WITH_SMALL_UPSTREAM_PATCH** — design implemented for Codex
0.160.1. Validation for this task is exclusively static: it does not establish
that the port builds or that a real session works on OpenBSD.

## Follow-up: codex-core compiler allocation failure

An OpenBSD build report for 0.162.0 shows rustc aborting with an allocation
failure while compiling codex-core at `opt-level=2`, `codegen-units=1`, and
without embedded bitcode. The earlier single-codegen-unit setting did not
solve the failure. It can increase the size of the LLVM module processed
at once; serial Cargo jobs and code generation unit size are separate concerns.

The port keeps `MAKE_JOBS=1`, removes the global single-unit override, and
sets `CARGO_PROFILE_RELEASE_LTO=off`. Cargo distinguishes `lto=false`, which
can still enable local ThinLTO, from `lto="off"`, which disables it entirely.
The post-configure hook appends a package-specific profile to the Cargo
module's `${WRKDIR}/.cargo/config.toml`:

```toml
[profile.release.package.codex-core]
opt-level = 1
codegen-units = 16
```

This reduces optimization work for codex-core and divides it into smaller
code generation units. Other crates retain the module's optimization and
codegen-unit settings. The configuration and environment also apply during
Cargo installation. Lower optimization and disabled LTO may reduce runtime
performance; lower compiler memory usage remains to be measured on OpenBSD.
See the [Cargo profile documentation](https://doc.rust-lang.org/cargo/reference/profiles.html).

The allocation error and SIGABRT do not distinguish exhausted system memory
from a process data limit. On OpenBSD, `RLIMIT_DATA` covers malloc and
anonymous mmap allocations; see [getrlimit(2)](https://man.openbsd.org/getrlimit.2).
Check limits in the actual build environment, including the build user's
limits when using privilege separation. Do not infer them only from the
interactive user's shell.

After copying the updated port into the OpenBSD ports tree, reconfigure it
with a clean build so the new hook runs:

```sh
cd /usr/ports/devel/codex
make clean
make configure
cat "$(make show=WRKDIR)/.cargo/config.toml"
make show=MODCARGO_ENV
make build
```

The codex-core rustc invocation must show `-C opt-level=1`,
`-C codegen-units=16`, and `-C lto=off`. Inspect memory and limits on the build
machine if it still fails:

```sh
ulimit -a
swapctl -sk
ps -ax -o pid,rss,vsz,command | grep '[r]ustc'
```

These commands are for later OpenBSD validation. Only the generated TOML
and port changes were checked statically during this follow-up; no build
or memory measurement was performed.

## Update to Codex 0.162.0

The port targets tag `rust-v0.162.0`, commit
`c1382380de69521303b416720a52f42d51af6248`. The system daemon layout,
manifest validation, update guards, and memory settings remain unchanged.
The daemon patches apply unchanged; upstream now also uses the managed
daemon for eligible plain `codex remote-control` invocations.

Four patches are refreshed. The apply_patch handler patch now uses upstream's
verification APIs without an explicit line-ending mode; upstream preserves
line endings by default. The OpenBSD exception still applies only to local
environments with full disk read access, preserving verification contexts
for remote environments and restricted read policies.

Crossterm is supplied by openai-oss-forks at revision
`ed1cdab335221515706178d68495bba2aed1924f`, matching Cargo.lock. Its Unix
backend and dependencies remain applicable to OpenBSD. Registry changes
replace age/age-core with 0.12.1/0.12.0, update their localization and macro
dependencies, and add hpke 0.12.0. All eleven added or updated registry
archives were verified against Cargo.lock and reviewed; none declares a
native library through `links` or adds a build dependency. No new native
library dependency or installed file change was identified. V8 150.4.0,
aws-lc-sys 0.45.0, and kqueue 1.1.1 remain unchanged, with archive checksums
verified against Cargo.lock.

All 83 patches apply to clean sources without fuzz, offsets, or rejects.
The modified Rust files pass rustfmt checks; no type check, build, or runtime
test was performed. As in the previous update, `distinfo` and `crates.inc`
are retained and must be regenerated using [UPDATE.md](../../UPDATE.md)
before building on OpenBSD. Temporary sources are deleted after validation.

## Update to Codex 0.161.0

The 0.161.0 update targeted tag `rust-v0.161.0`, commit
`979011409de0a60b52f179721948e65531d26144`. The analysis below records the
original 0.160.1 integration; its system daemon layout and ownership model
remain in place for 0.161.0. Upstream adds daemon diagnostics, preserves
previous stderr logs, and passes `--analytics-default-enabled` while honoring
explicit analytics opt-outs. The package resolver, manifest validation, and
system update guards remain compatible.

The update refreshes five patches and removes the chatgpt recursion-limit
patch, which upstream has incorporated. The new Git dependency on rmcp 3.3.0
and its rmcp-macros crate is supplied by a pinned rust-sdk DIST_TUPLE and a
local Cargo path. Registry changes add file-id 0.2.3, replace process-wrap
9.0.1 with 10.0.0, and remove the registry copies of rmcp/rmcp-macros 3.2.0.
The patched V8 150.4.0, aws-lc-sys 0.45.0, and kqueue 1.1.1 versions are
unchanged; their archive checksums match the new Cargo.lock. The two new
registry archives were also verified against Cargo.lock and reviewed for
Unix/OpenBSD compatibility. No new native library dependency or installed
file change was identified.

The 0.161.0 update initially set `MAKE_JOBS=1` and
`CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1` for memory-constrained machines.
The global single-unit setting is superseded by the allocation-failure
follow-up above; Cargo jobs remain serialized. It replaced the earlier
CPU-count-based MAKE_JOBS setting described below.

All 83 remaining patches apply to clean sources without fuzz, offsets, or
rejects. This update uses static analysis only. The existing `distinfo` and
`crates.inc` are intentionally retained; both need regeneration on OpenBSD
before building, including the new rust-sdk source archive. Use the Cargo
workflow in the repository's [UPDATE.md](../../UPDATE.md), with
`devel/codex` as the port directory. Temporary sources are deleted when the
update is complete.

## Scope and initial state

Source: tag `rust-v0.160.1`, commit
`d27764b82f7118f674371e6d6e76271d9d606edb` in openai/codex.
A temporary copy was analyzed and deleted when the work was complete.

The existing port **already enabled the daemon** through four
`app-server-daemon` patches and `CODEX_SYSTEM_DAEMON_PATH=${LOCALBASE}/bin/codex`.
There was no patch setting `daemon_auto_start=false` or excluding OpenBSD.
The disabled component was the **executable updater**, not the app-server
process. This task completes and strengthens that integration: it installs
metadata, preserves a layout recognized by upstream, validates versions, and
corrects the actions offered by the maintenance menu.

The previous `MAKE_JOBS` change in the Makefile is preserved unchanged.
`distinfo` and `crates.inc` are also not regenerated. The existing `distinfo`
still names the 0.160.0 tarball: it must be updated before rebuilding 0.160.1
(see the commands at the end).

## Upstream architecture and complete flow

The following links pin the version analyzed; file names without links are
relative to the upstream repository.

1. **Executable and dispatch.** `codex-rs/cli/Cargo.toml` defines the `codex`
   binary in the `codex-cli` package; it depends on `codex-app-server` and
   `codex-app-server-daemon`. `cli/src/main.rs::main` uses
   `codex_arg0::arg0_dispatch_or_else`, followed by `cli_main`. Argument
   dispatch distinguishes the TUI session, `app-server`, and `app-server daemon`.
   `AppServerDaemonSubcommand`, `LifecycleCommand`, `LifecycleOutput`, and
   `BootstrapOutput` represent process management.
2. **Enablement.** `features/src/lib.rs` defines
   `Feature::DaemonAutoStart`, key `daemon_auto_start`, `Stage::Stable`, and
   `default_enabled: true`. The `run_main` function in `codex-tui` reaches the
   orchestration in `tui/src/startup_orchestration.rs`.
   `daemon_startup::exclusion` and `config_exclusion` preserve upstream
   restrictions: for example, `--no-daemon`, `--oss`, executor selection,
   workload identity, and CLI overrides that cannot be reproduced. No
   OpenBSD exclusion is added.
3. **Interactive startup.** The `auto_start_daemon` block calls
   `codex_app_server_daemon::start_with_features`. In
   `app-server-daemon/src/launch.rs`, this function acquires the operation lock,
   preserves overrides, and calls `Daemon::start`.
4. **Central resolution.** `Daemon::from_environment`,
   `current_installation`, and `current_managed_codex_bin` use
   `managed_install::managed_codex_bin`. Upstream selects
   `packages/app-server-daemon/current/bin/codex`; `package_root` retains
   `packages/standalone/current` if it identifies an older daemon through
   PID records or logs. `managed_codex_file_name` selects `codex` or `codex.exe`.
5. **Initial preparation.** `prepare_install::prepare` uses
   `InstallContext::current().package_layout` and `prepare_from_package`.
   The first startup does not necessarily download anything: it normally
   **copies the entire CLI package** into the home directory. `validate_package`
   requires a manifest, executable, code-mode host, and ripgrep; Linux also
   requires bwrap, and Windows requires its helper programs. `package_tree`
   copies the tree and computes its BLAKE3 digest. Staging under `releases/`,
   locks, and atomic selection of `current` are used.
   `update_from_cli` allows explicit replacement with `--from-cli`.
6. **Version and platform.** `CodexPackageManifest.version` is a
   `semver::Version`; `stable_version` filters stable versions.
   `prepare_install::platform_target` enumerates Darwin, Linux GNU/musl, and
   Windows MSVC; it compares the JSON `target` and `entrypoint`. Executable
   identity is computed by `managed_install::executable_identity`.
   `managed_codex_version` runs the selected executable with `--version`, and
   `parse_codex_version` extracts the second token.
7. **Process.** `Daemon::start_managed_backend` constructs `BackendPaths` and
   calls `backend::pid_backend`, `PidBackend::start`, and `start_inner` in
   `backend/pid_start.rs`. It canonicalizes the executable, reserves a PID file,
   opens the log, and constructs a `tokio::process::Command`.
   `PidBackend::command_args` produces:

   ```text
   codex app-server [--remote-control] --listen unix:// [-c features.X=Y]
   ```

   `--managed-daemon` is added when the CLI supports it. The child receives
   null stdin and stdout, with stderr directed to the log; on Unix, it calls
   `setsid()` in `pre_exec`, followed by `Command::spawn()`, which ultimately
   executes the native binary. The child `codex` returns to `cli_main`, takes
   the `Subcommand::AppServer` branch, and calls
   `codex_app_server::run_main_with_transport_options`.
8. **Publication and readiness.** `PidRecord` stores the PID, start time,
   optional process identity, and executable digest.
   `read_process_details` obtains `stat` and `lstart` through `ps` in the
   Unix fallback. `wait_until_ready` uses `client::probe`, with polling and
   a ten-second startup timeout.
9. **IPC.** `codex-app-server-transport`, `codex-uds`,
   `AppServerTransport::from_listen_url`, `start_control_socket_acceptor`, and
   `codex-app-server-client::RemoteAppServerClient` implement WebSocket over
   a Unix socket and JSON-RPC. `initialize` / `initialized` exchange
   `InitializeParams`, capabilities, and `InitializeResponse.user_agent`.
   `client::parse_version_from_user_agent` reads the server version.
   The TUI selects `AppServerTarget::LocalDaemon`, and
   `daemon_startup::compatibility_warning` also checks server features through
   RPC. No separate protocol version negotiation or mandatory build ID was
   found for this lifecycle.
10. **Stop and restart.** `Daemon::stop` and `restart_with_settings` maintain
    ownership through PID records and locks. `PidBackend::stop_with_grace`
    checks identity, sends SIGTERM, and finally sends SIGKILL if necessary;
    upstream drains work and preserves recovery with `--managed-daemon`.
    Exiting the CLI does not necessarily stop the daemon: it is a detached
    process for each user, shared by subsequent clients.
11. **Upstream updates.** `ensure_managed_updater` checks settings,
    `is_stable_standalone_release`, `auto-update-version`, and
    `supports_daemon_update_loop`. The `pid-update-loop` process enters
    `update_loop::run` and `run_with_http`; it initially waits five minutes,
    then uses the configured interval (sixty minutes by default).
    `update`, `request_manual_update`, `manual_update::request/run`, and
    `migration::run` handle explicit updates, including pinned local packages
    and legacy migrations.
12. **Upstream download and installation.** `fetch_installer_script` retrieves
    `https://chatgpt.com/codex/install.sh` (PowerShell on Windows);
    `run_installer_script` executes it with `CODEX_INSTALL_DAEMON_ONLY` flags
    and selection guards. `scripts/install/install.sh` resolves release
    metadata on releases.openai.com/GitHub, the
    `codex-package-<target>.tar.gz` asset, and checksums;
    `download_file_with_fallback` and `install_package_release` download and
    extract with `tar`, install a release, and repoint `current`. There is
    a fallback to a platform npm tarball through
    `install_legacy_platform_npm_release`; npm is not a required dependency
    for a Rust daemon. These paths are unreachable in the mode that uses
    a daemon provided by the system.

Primary sources:
[TUI orchestration](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/tui/src/startup_orchestration.rs),
[resolver](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/managed_install.rs),
[preparation](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/prepare_install.rs),
[PID startup](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/backend/pid_start.rs),
[updater](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/app-server-daemon/src/update_loop.rs).

## The `can't start` error: facts and limits

Searching the entire 0.160.1 tree for the literal `can't start`, its
curly-apostrophe variant, and `couldn't start` finds no source of a daemon-related
`can't start` message. The `couldn't start` messages that do exist belong to
`cli/src/state_db_recovery.rs`, which handles database recovery; they do not
allow the reported message to be attributed to that path. Without the command,
version, and full error, its source and original errno cannot be determined.
No root cause is invented for that case.

The failure of a **bare upstream installation** can be reconstructed:

- `managed_codex_bin` normally returns
  `~/.codex/packages/app-server-daemon/current/bin/codex`, which does not yet exist.
- `prepare_from_package` finds `InstallContext.package_layout == None` if only
  `/usr/local/bin/codex` was installed without a layout or manifest, and fails
  with `this CLI has no complete local package; install a packaged Codex CLI
  or use the standalone installer`. It never reaches spawn.
- If an upstream bundle is supplied, `platform_target()` fails with
  `unsupported packaged daemon platform openbsd/x86_64` or
  `openbsd/aarch64`, before validating or copying the package. The shell
  installer also provides no OpenBSD artifact. Adding only the JSON does
  not resolve this.
- These are **package provisioning** blockers, not missing app-server source
  code: `ensure_supported_platform()` accepts `cfg(unix)`.

The previous patches bypassed the first two paths; they therefore cannot be
presented as proven causes of a failure in the already patched port.
A remaining failure could involve executable permissions, libraries, limits,
PID identification, previous state, or the socket. Upstream already reports:

- `failed to spawn detached app-server process using <path>`, from
  `PidBackend::start_inner`, preserving the `spawn`/`setsid` error;
- `failed to record pid-managed app-server process <pid> startup`, plus
  the tail of stderr when identification fails;
- `app server did not become ready on <socket>`, from
  `wait_until_ready`/`app_server_not_ready_context`, with the path, version,
  and up to 4096 bytes from the end of the log;
- TUI orchestration formats the `anyhow` error chain with `{err:#}`.

The implementation adds diagnostics for a missing package, invalid manifest,
incompatible versions, and a version query timeout, directing users to
`pkg_add` without suggesting a download as a repair.

## How the daemon is built

The `codex-app-server-daemon` package is a **lifecycle library**;
it does not define another daemon executable. The actual server is
`codex-app-server`, which provides both a library and the standalone
`codex-app-server` target. The `codex` CLI already links that library and
provides the `app-server` subcommand.

The port therefore builds the daemon when it builds `codex-cli --bin codex`.
There is no need to compile another copy or obtain source code from another
repository. A standalone `codex-app-server` is not a direct replacement for
`codex` in `PidBackend`: the backend also expects `--version`,
`app-server ...`, and `app-server daemon ...` commands from the multitool CLI.
That contract is preserved by reusing the CLI executable.

## Manifest and Node/npm

The actual file name is **`codex-package.json`**, defined by the
`PACKAGE_METADATA_FILENAME` constant in `codex-install-context`.
`scripts/codex_package/layout.py::build_package_dir` generates it with:

| Upstream field | Meaning |
| --- | --- |
| `layoutVersion` | Layout version, currently 1 |
| `version` | Package semver; defaults to workspace.package.version |
| `target` | Native distribution target triple |
| `variant` | `codex` or `codex-app-server` |
| `entrypoint` | Relative path, such as `bin/codex` |
| `resourcesDir` | `codex-resources` directory in the complete bundle |
| `pathDir` | `codex-path` directory in the complete bundle |

`CodexPackageLayout::from_exe` canonicalizes the executable;
`from_package_bin_dir` recognizes a `bin/` directory whose parent contains
the JSON. `InstallContext::package_manifest` deserializes only `version` as
semver. `prepare_from_package` also reads `target` and `entrypoint` for the
upstream copy operation. Layout detection does not depend on npm or a tree
in the home directory.

The port installs the first five fields. It does not declare resource or
PATH directories that it does not install. The Rust implementation already
treats those **directories as optional**: `code_mode_host_program` looks for
the host next to the binary, and `rg_command` uses ripgrep from RUN_DEPENDS.
This installation is not presented as a complete bundle that can copy itself:
system mode bypasses `validate_package`/`package_tree` and all copying.

`scripts/codex_package/targets.py` and `cargo.py` build the bundle binaries
from source. `codex-cli/scripts/build_npm_package.py` assembles the
`@openai/codex` metapackage and native variants with a vendor tree.
`codex-cli/bin/codex.js::findCodexExecutable` selects the target triple based
on `process.platform`/`process.arch`, locates the platform dependency through
`require.resolve(<package>/package.json)`, and launches its Rust binary.
Its selector does not include OpenBSD. The shim exports
`CODEX_MANAGED_BY_NPM`/BUN/PNPM/VITE_PLUS and `CODEX_MANAGED_PACKAGE_ROOT` for
classification and diagnostics. **npm's `package.json` is not the runtime's
`codex-package.json`**. The standalone fallback to npm tarballs extracts their
vendor tree with tar; it does not require running Node either.

The port invokes the Rust binary directly. It does not install the JS shim,
add Node/npm, or adapt its selector to a Linux artifact.

Sources:
[installation context](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-rs/install-context/src/lib.rs),
[manifest generator](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/scripts/codex_package/layout.py),
[npm shim](https://github.com/openai/codex/blob/d27764b82f7118f674371e6d6e76271d9d606edb/codex-cli/bin/codex.js).

## Alternatives investigated

| Alternative | Result |
| --- | --- |
| 1. Configurable daemon path | The upstream resolver has no override for external provisioning; the previous central patch is retained |
| 2. Environment variable | The port already added `CODEX_SYSTEM_DAEMON_PATH`; this is a **compile-time** variable consumed with `option_env!`, not a user override at runtime |
| 3. Build constant | The variable above is embedded in the crates; ownership cannot be changed by the session environment |
| 4. Manifest generated by the port | Implemented with SUBST_CMD, version `${V}`, and the native OpenBSD target |
| 5. Installation under PREFIX | Implemented in libexec/codex with the upstream bin/ layout and public symlinks |
| 6. Bypass only download/update | Guards in prepare, update_from_cli, update, pid-update-loop, and ensure_managed_updater; no guards that disable start/stop |
| 7. Reuse start/stop/IPC | Existing PID backend, setsid, signals, sockets, locks, probes, and recovery |
| 8. Small system-provided mode | Central resolver, version validation, and public system_daemon_path API for the menu |
| 9. Central package resolver | managed_install::managed_codex_bin returns the compiled path before inspecting user packages |
| 10. Same source tree/build | CLI and daemon are the same ELF executable; the code-mode host is built in the same workspace/version |

The external path is not inferred from a `current` file in the home directory,
and a missing package executable never triggers a download fallback.

## Layout, process, and platform

```text
${PREFIX}/bin/codex -> ../libexec/codex/bin/codex
${PREFIX}/bin/codex-code-mode-host -> ../libexec/codex/bin/codex-code-mode-host
${PREFIX}/bin/codex-logs-client
${PREFIX}/libexec/codex/
    codex-package.json
    bin/
        codex                 # CLI and app-server, a single executable
        codex-code-mode-host
${PREFIX}/share/doc/codex/     # existing documentation
```

`libexec/codex/bin` preserves the `bin/` convention recognized by upstream:
there is no need to modify `codex-install-context` or install a global
manifest at `${PREFIX}/codex-package.json`. The public `bin/codex` symlink
is needed for the user CLI. The host symlink preserves its existing path,
while internal lookup uses the copy next to the executable.
PLIST records the actual ELF files with `@bin`; symlinks are recorded as such.

The targets are `x86_64-unknown-openbsd` and `aarch64-unknown-openbsd`.
OpenBSD is not added to download lists without artifacts, nor aliased to
Linux. Lifecycle and transport already select `cfg(unix)` for OpenBSD:
setsid, flock/locks, SIGTERM/SIGKILL, Unix sockets, private 0700 modes, and
socket permissions. The ps patch with `LC_ALL=C` and `TZ=UTC` is retained
for identity based on `lstart` across different terminals.
The actual socket is published under `/tmp/codex-daemon-<uid>/<hash>`; the
advertised CODEX_HOME path is a symlink, with upstream locks and ownership.

There is no rc.d script, service account, system startup, or periodic package
updater. The daemon remains available after exiting a TUI and restarts on
demand after a reboot or an explicit stop.

## Inventory of ~/.codex/packages

In the Rust flow examined, the actual roots are `standalone` and
`app-server-daemon`; no other daemon provider was found under that root.

| Use | Handling |
| --- | --- |
| `standalone/releases`, `app-server-daemon/releases` | Packages containing CLI/daemon executables, code-mode host, rg, and platform resources; system mode neither creates nor selects these releases |
| `current`, `auto-update-version`, install locks/staging | Selection and preparation metadata for those upstream packages; not needed in system mode |
| `~/.codex/app-server-daemon` | State: PID, settings, locks, stderr logs, loaded-threads.json; retained |
| `~/.codex/app-server-control` | IPC rendezvous/lock; retained, with a protected temporary socket for actual communication |
| Other caches, history, auth, plugins, and user metadata | Not a daemon installation; neither deleted nor moved |
| Optional components | Bundled Linux/Windows resources are not required on OpenBSD; rg is a RUN_DEPENDS dependency, and the host is installed from the build. Plugins/MCP/other optional downloads retain their existing policies |

`~/.codex/packages` is not deleted: it may contain previous installations,
software managed by the user, or other uses that should not be migrated
through indiscriminate deletion.

## Patches and port changes

The five Rust files related to this integration are:

| Patch | Purpose |
| --- | --- |
| `patch-codex-rs_app-server-daemon_src_managed_install_rs` | Existing: priority for the compiled path and exclusion of the latest-channel updater |
| `patch-codex-rs_app-server-daemon_src_prepare_install_rs` | Extended: bypass copying; validate manifest semver and ELF version with a timeout; reject --from-cli |
| `patch-codex-rs_app-server-daemon_src_lib_rs` | Extended: system_daemon_path API, preserved lifecycle, update guards, pkg_add diagnostics, and rejection of an active daemon running another version |
| `patch-codex-rs_app-server-daemon_src_backend_pid_rs` | Existing: stable ps identity on OpenBSD with fixed locale/time zone |
| `patch-codex-rs_tui_src_app_daemon_menu_rs` | New: only installation/replacement actions are disabled; /daemon points to pkg_add and restart, while the process remains enabled |

Other port patches, including Cargo, V8, and the startup update policy,
are not modified during this task.

Makefile: compiled path to libexec, manifest generation, relocation of the
two binaries and creation of symlinks during post-install, and `REVISION=0`
so pkg_add recognizes the change from 0.160.1 without a revision.
PLIST: actual libexec paths, manifest, and symlinks.
`files/codex-package.json`: small template with five fields.
`pkg/README`: usage, ownership, layout, restart, socket, and migration.
MODULES, BUILD_DEPENDS, LIB_DEPENDS, and RUN_DEPENDS are unchanged.
The previous MAKE_JOBS override is retained.

## Versioning, resulting flow, and updates

```text
make -> codex-cli/codex + codex-code-mode-host + manifest with the same ${V}
  |
pkg_add codex
  +-- installs shared CLI/daemon ELF, host, manifest, and symlinks
         |
       codex
         +-- daemon_auto_start, upstream eligibility policy
         +-- central resolver -> system executable
         +-- manifest.version == CARGO_PKG_VERSION
         +-- executable --version == CARGO_PKG_VERSION
         +-- start with setsid / PID backend
         +-- initialize / initialized / health check / JSON-RPC over UDS
         +-- running app_server_version == CARGO_PKG_VERSION on startup/reuse
         +-- existing stop / restart and recovery
```

Upstream allows different versions in some installations/updates.
System mode tightens startup checks: the CLI, manifest, and new executable
must have exactly the same version. If reuse of a running daemon with
another version is attempted, the user is notified and asked to run
`codex app-server daemon restart`; work is not automatically interrupted,
and no automatically downloaded copy is selected. Using the same ELF for
the CLI and server also guarantees the identity of the installed build.
Upstream records a BLAKE3 digest of the process; no additional protocol
version or build ID is invented for the manifest.

`pkg_add -u` replaces the files belonging to the package together; a process
that is already running retains its old image. The user explicitly restarts
the daemon to pick up the new build, including when only the port revision
changes and the upstream version stays the same.
`update` returns UpdateStatus::Unsupported with pkg_add guidance;
`--from-cli` and `pid-update-loop` are rejected before copying/downloading.
An existing settings.json with autoUpdateEnabled=true does not enable the
updater in system mode. Codex only modifies user state files.

## Maintainability and static validation

The five integration patches add 103 Rust lines and replace three lines,
including the existing guards. The new extension affects three Rust files;
the other two daemon patches are retained. The layout does not require
patching the manifest resolver, JS shims, protocol, or app-server engine.
The risk of conflicts is moderate in `Daemon::start`, `prepare`, and the
TUI menu, which upstream changes frequently; the central resolver is small
and easy to reapply.

Reasonable upstream proposals include a daemon provider compiled by the
distributor, public ownership information for the UI, and metadata/version
validation, with a configurable package manager message. The ps locale/TZ
correction is also independent of binary distribution.

Checks performed: all 84 Codex patches were applied to the exact sources and
patched crates without fuzz, offsets, or rejects; checksums for these crates
were verified against Cargo.lock. The two micro 2.0.15 patches were also
checked without fuzz or offsets. The three new/extended patches were
regenerated and reapplied to pristine sources with identical results.
rustfmt checked the syntax/format of the modified files (this is not a type
check). A temporary file/symlink layout was used to check canonicalization,
JSON and host lookup, and PLIST correspondence for both architectures.
bmake expanded both target triples; the resulting JSON is valid.
No compilation, Rust tests, Codex startup, package installation, or push
was performed.

## Follow-up validation: run on OpenBSD -current

From a checkout placed in a ports tree compatible with -current:

```sh
cd devel/codex
make clean
make makesum                    # current distinfo still names 0.160.0
make build
make fake
make lib-depends-check
make update-plist
# Review the generated PLIST before creating the package.
make package
# If an old daemon exists, stop it with the old CLI before updating.
codex app-server daemon stop
# For a first installation, skip the stop above if codex does not exist.
doas pkg_add -r "$(make show=PKGFILE)"
pkg_info -L codex
pkg_info -f codex
ldd /usr/local/libexec/codex/bin/codex
ldd /usr/local/libexec/codex/bin/codex-code-mode-host
ls -l /usr/local/bin/codex /usr/local/bin/codex-code-mode-host
cat /usr/local/libexec/codex/codex-package.json
/usr/local/libexec/codex/bin/codex --version
```

To test lifecycle and the absence of copies without touching the usual
configuration, choose a new CODEX_HOME. These commands test the daemon first,
then the TUI (the user should complete login if needed):

```sh
CODEX_HOME=$(mktemp -d /tmp/codex-daemon-check.XXXXXXXX)
export CODEX_HOME
codex app-server daemon start
codex app-server daemon version
ps -ax -o pid,ppid,command | grep '[c]odex.*app-server'
ls -l "$CODEX_HOME/app-server-control/"
cat "$CODEX_HOME/app-server-daemon/daemon.pid"
cat "$CODEX_HOME/app-server-daemon/daemon.stderr.log"
codex --enable daemon_auto_start
# After exiting the TUI: it should still be running and reusable.
codex app-server daemon version
codex app-server daemon restart
codex app-server daemon update       # Unsupported + pkg_add; no download
codex app-server daemon update --from-cli --yes  # rejected before copying
# It should still work after rejecting internal updates.
codex app-server daemon version
codex app-server daemon stop
test ! -e "$CODEX_HOME/packages/app-server-daemon"
test ! -e "$CODEX_HOME/packages/standalone"
find "$CODEX_HOME" -type f \( -perm -0100 -o -perm -0010 -o -perm -0001 \) -print
# No automatically downloaded codex/host should appear.
```

`version` should show `managedCodexPath` in libexec and compatible versions;
PID/IPC should work during start, reuse, restart, and stop. A clean home
directory allows checking that no second copy was generated without confusing
it with old files. To confirm TUI auto-start from scratch, run
`codex --enable daemon_auto_start` again after stop and query `version` from
another terminal with the same CODEX_HOME.

To check package updates during normal use:

```sh
doas pkg_add -u codex
codex app-server daemon restart
codex app-server daemon version
```

If a binary or the manifest is missing, preserve the full message and log:
the expected repair is to reinstall the package, not install a daemon in
the home directory. The interactive test and the historical `can't start`
error still require real-world verification and, for the latter, the original
log.
