# Initial OpenBSD ports status

Source review: 2026-09-05; sdwdate extension: 2026-09-06.
Development host: Fedora Atomic (Linux).
No OpenBSD build, package, install, or VPN runtime test has been performed.
`READY_FOR_OPENBSD_TESTING` means a candidate port is ready to enter native
testing, not that the program works on OpenBSD.

## Scope and reference tree

The local repository is a WIP overlay, not a full ports checkout: it has no
`infrastructure/`. Existing unrelated changes, including moved ports and
tracked deletions, were preserved. None of the nine targets was found in
the overlay or in the inspected current official tree.

Conventions were checked against OpenBSD ports revision
`4cd0801cc18f05d517285943c02daa3a6bb00726`, including `infrastructure/mk`,
Python, Go, Cargo and CMake modules, `net/i2pd`, `games/sauerbraten`, and
current examples for Rust, Go, Python/Qt and header-only libraries.
The Rust module is **devel/cargo**, not `lang/cargo`.
See the [Porter's Handbook](https://www.openbsd.org/faq/ports/guide.html)
and [bsd.port.mk(5)](https://man.openbsd.org/bsd.port.mk).

No standalone dependency ports were created. No host deployment, ports
infrastructure, or unrelated port was changed. No commit or push was made.
Upstream README copies and aggregated THIRD-PARTY-NOTICES are not installed,
as requested. OpenBSD `pkg/README*` files retain useful runtime warnings.
Embedded upstream source/resource license notices remain with those files.

## Summary

| PKGPATH | Stable source | Status |
| --- | --- | --- |
| net/sdwdate | 29.0-1, b420a67339bf5ba2ac39ec387b3b46d3c769d67d | REQUIRES_OPENBSD_RUNTIME_WORK; static native implementation |
| devel/nuklear | v4.13.3 | READY_FOR_OPENBSD_TESTING |
| devel/checkmake | v0.3.2 | READY_FOR_OPENBSD_TESTING |
| devel/mbake | v1.4.6 | READY_FOR_OPENBSD_TESTING |
| sysutils/doasedit | 1.0.9 | BLOCKED_UPSTREAM; BROKEN guard |
| editors/msedit | v2.0.0 | READY_FOR_OPENBSD_TESTING |
| net/i2pd-tools | 2.58.0 | READY_FOR_OPENBSD_TESTING |
| games/assaultcube | v1.3.0.2 | READY_FOR_OPENBSD_TESTING; restricted redistribution |
| net/onionshare | v2.6.5 | READY_FOR_OPENBSD_TESTING; privacy/runtime unverified |
| net/mullvad | 2026.4 | CLI: READY_FOR_OPENBSD_TESTING; daemon: REQUIRES_OPENBSD_RUNTIME_WORK |

All versions use released tags/assets, not moving branches or release
candidates. Exact extra revisions and language dependencies are pinned in
the Makefiles, modules.inc/crates.inc, Cargo.lock and distinfo.

## Nuklear

[Upstream v4.13.3](https://github.com/Immediate-Mode-UI/Nuklear/tree/v4.13.3).
ANSI C, intentionally header-only. Installs `include/nuklear.h` and the main
license; no shared library or invented pkg-config ABI. License: MIT/public
domain, with the embedded font's notice retained in the header.

Dependency classification: base C headers/libc (and libm as selected by a
consumer); no existing/new dependency port; upstream embedded font; optional
SDL/GLFW/OpenGL/X11 backends and demos excluded; no upstream automated test
target. No source patches were necessary. Linux C89 implementation/header
smoke compilation passed. Native: compile representative consumers with
optional font/vertex-buffer configurations and verify the header inventory.

## checkmake

[Upstream v0.3.2](https://github.com/checkmake/checkmake/tree/v0.3.2).
Go module, MIT. `lang/go` handles dependencies and offline build configuration.
The generated release man page is an explicit distfile, not regenerated with
Pandoc. Version/build provenance is injected; a small patch obtains the Go
version from `runtime.Version()` when bypassing upstream's Makefile.

Dependency classification: base libc/pthread candidate WANTLIB; existing
lang/go build dependency through the module; 26 pinned Go module archives
and nine additional mod-only records (61 dependency files); no new ports;
Go test dependencies remain in the same pinned module graph; Pandoc and
development linters excluded. Main archive plus manual makes 63 distfiles.
Linux offline `go test ./...`, build and version smoke checks passed.
Native: all normal port checks, installed manual and version output, and
Makefile linting fixtures. It is not a complete BSD make semantic checker.

## mbake

[Upstream v1.4.6](https://github.com/EbodShojaei/bake/tree/v1.4.6).
The repository is bake, but the Python distribution and command are mbake.
MIT; Python >=3.9; Hatchling. Candidate PLIST comes from the built wheel.

Dependency classification: existing Python module infrastructure, py-rich,
py-typer and GNU make; pytest test-only; no private modules or new ports;
VSCode extension, development linters and old-Python tomli dependency
excluded. GNU make is intentional: the OpenBSD patch selects `gmake`, also
in relevant test fixtures. This does not advertise BSD make compatibility.
OpenBSD version reporting does not query the network; application
self-updating is refused in favor of pkg_add.

Linux wheel build and 211 tests passed after the patches. The formatter
does not need network access during package construction. Validation of
untrusted Makefiles is not a sandbox: GNU make expansion can execute
`$(shell ...)` even during a dry run. Native: run pytest, CLI format/check/
validate/version, XDG configuration handling, and confirm that BSD make is
never accidentally invoked by validation.

## doasedit

[Upstream 1.0.9](https://codeberg.org/TotallyLeGIT/doasedit/src/tag/1.0.9),
tag/inspected HEAD `45ff6eb28afea2e35bb332574c7f1e3473046158`.
Independent MIT shell utility; base sh/doas/mktemp/dd and an editor chosen
by the user. No extra dependency port, vendoring, or automated test suite.
Shell syntax and version invocation passed on Linux. Base OpenBSD dd
supports the `status=none` argument used here.

The port deliberately has BROKEN set. Whole-script and history inspection
found privileged check/open pathname races, symlink following, missing
parent-directory validation, collisions among temporary/edit/backup names,
no concurrent-change check, truncation before successful writeback, and
cleanup that can discard recovery data on failure/signals. Private mktemp
permissions are good but do not solve these problems. Broad authorization
to run doas dd cannot be made a narrow editing privilege by shell checks.

No unsafe shell workaround or doas.conf grant was added. Upstream needs a
reviewed descriptor-based privileged helper and safe recovery protocol.
`pkg/README` records the detailed findings. Do not remove BROKEN merely to
install this on production files. Native security tests require a disposable
VM, concurrent rename/link attacks, interrupted writes, and signal tests
after the redesign; packaging alone cannot validate that boundary.

## Microsoft Edit / msedit

[Upstream v2.0.0](https://github.com/microsoft/edit/tree/v2.0.0).
MIT, Rust >=1.93, internal edit/lsh/stdext workspace. Only the terminal
binary is installed, renamed from `edit` to `msedit` to avoid command-name
ambiguity. The initial supported architecture list is amd64/aarch64.

Dependency classification: base libc/pthread/libm through Rust's module
WANTLIB; existing Rust build infrastructure and runtime textproc/icu4c;
99 pinned registry crates through MODCARGO, no new ports; archivers/zstd
test-only; other-target dependencies are lockfile inputs, not OpenBSD
libraries. ICU is dynamically loaded, not linked or embedded. Absolute
OpenBSD library paths and non-renamed ICU symbols are configured explicitly;
ICU is RUN_DEPENDS rather than speculative WANTLIB.

Upstream Unix terminal support already covers the selected APIs; no source
patch was needed. Linux release build succeeded. Debug-profile tests passed
65 tests with one upstream ignore; the debug profile is intentional because
an upstream should-panic doctest exercises a debug arena assertion. Linux
ICU uses different sonames/symbol renaming from OpenBSD, so the Linux test
environment was adjusted only outside the port.

Native: validate dlopen resolution against OpenBSD ICU, terminal raw-mode
restoration, suspend/resume, resize, Unicode, search, clipboard/OSC52 and
both architecture builds. Regenerate PLIST and native library requirements.

## i2pd-tools

[Tools 2.58.0](https://github.com/PurpleI2P/i2pd-tools/tree/2.58.0),
tag commit `2583ba8eb3ab988a1dd67b864c6a9a1a4d5814e8`.
The exact i2pd gitlink is
`80080fd8f5df5c8c07df044458eedbf8fbbbe86c`; its archive is a second distfile.
It is installed into the empty submodule directory during extract. The
separately packaged i2pd daemon is not a suitable internal SDK dependency.
GNU make, C++17; BSD-3-Clause tools and internal i2pd source.

Dependency classification: base LibreSSL, zlib, pthread, C/C++ runtime;
existing devel/boost and build-only GNU make; pinned upstream i2pd source
embedded as required by upstream; no new dependency ports. Boost.System is
header-only and FS.h selects std::filesystem. Only Boost.Program_options
is explicitly linked. UPnP and git-based version discovery are disabled.
No upstream tool test target exists; the daemon's unrelated test suite is
not substituted for one.

The Makefile patch recognizes OpenBSD instead of falling through to Windows
and avoids Linux's libatomic flag. All 14 binaries built on Linux using
LibreSSL, not OpenSSL; dynamic dependency inspection agrees with the
candidate libraries. No -ldl/-lrt or speculative duplicate crypto port.

Binaries: autoconf, b33address, famtool, i2pbase64, keygen, keyinfo,
offlinekeys, regaddr, regaddr_3ld, regaddralias, routerinfo, vain, verifyhost,
x25519. All are installed under libexec/i2pd-tools with `i2pd-` prefixed
launchers to avoid collisions, notably GNU autoconf. Launchers use umask
077 for new keys. Existing file permissions, overwrites and symlink following
remain upstream behavior: use fresh paths in a private unprivileged directory.
routerinfo's firewall-output option emits iptables, not PF.

Native: compile against current base LibreSSL and Boost, derive WANTLIB,
exercise key generation/inspection/signatures with disposable keys, validate
each launcher and check filesystem/thread behavior. No production keys or
live network credentials were used in Linux experiments.

## AssaultCube

[Upstream v1.3.0.2](https://github.com/assaultcube/AC/tree/v1.3.0.2).
The tag archive contains both source and game data. An RC-labelled release
asset was not selected in place of the stable source tag. C++/GNU make.
Client, dedicated server and architecture-independent data are three
subpackages from one build; the server does not acquire graphical runtime
dependencies merely because the client uses them.

Dependency classification: base C/C++ runtime, pthread, zlib, OpenGL and X11;
existing SDL2/SDL2_image, OpenAL, libvorbis and ENet for the client; ENet for
the dedicated server; GNU make build-only. Convenience copies of system
libraries are not compiled. SDL_mixer and curl are not used by this source.
Data is included upstream, not separately fetched during build. No new
dependency ports; no automated upstream test suite.

Engine code has a modified zlib-style license. Assets have mixed restrictive,
no-modification and non-commercial terms; they are not covered by the code
license. Accordingly PERMIT_PACKAGE is restricted and PERMIT_DISTFILES is
Yes, following the nearby Cube-engine port precedent. See upstream's
[distribution conditions](https://assault.cubers.net/docs/license.html).
Do not redistribute this patched package as an unrestricted binary package.

Patches preserve OpenBSD compiler flags/FORTIFY, use OpenBSD's thread-name
API, permit system ENet, and replace the bundled ENet fork's incremental
CRC helper with equivalent base-zlib CRC32. Linux dedicated-server build
and link passed against a separately staged ENet 1.3.18. No server was
publicly launched. The graphical client was inspected but not built on
Linux because its development libraries were not installed.

Launchers keep user data out of the shared package tree. Server setup is
documented in pkg/README-server: private working directory, copied config/
maps, no root, no service autostart. Native: client rendering/audio/input,
IPv4/IPv6 behavior supported by upstream, localhost client/server protocol,
maps/demos/config/log writes, system ENet interoperability and public-server
security review. Candidate PLIST-data was generated from the shipped data
tree; license files embedded in assets were retained.

## OnionShare

[Upstream v2.6.5](https://github.com/onionshare/onionshare/tree/v2.6.5),
official source release asset. GPL-3.0-or-later, Python >=3.10, Poetry-core.
One port produces a lightweight onionshare-cli package and an onionshare
GUI package depending on it. Both wheels are built without isolation or
downloads; Qt is not a CLI runtime dependency. Web scripts, fonts, templates,
wordlists, locales and icons are already included in upstream resources.

Dependency classification:

- Base: Unix sockets, process/filesystem facilities; no bundled Tor binary.
- Existing build ports: Python, py-build, py-installer, py-poetry-core.
- Existing CLI runtime ports: py-cffi, py-click, py-colorama, py-gevent,
  py-packaging, py-qrcode, py-gevent-websocket, py-socks, py-stem, py-wsproto,
  tor, py-PyNaCl, py-psutil, py-unidecode, py-flask, py-flask-compress,
  py-requests, py-urllib3, py-waitress, py-werkzeug. Exact PKGPATHs are in
  Makefile; no unrelated Fedora dependency is inferred.
- Existing GUI ports: Qt6/PySide6, py-gnupg, desktop-file-utils, xdg-utils
  and the current GTK icon-cache helper. Python-GnuPG is GUI-only.
- Private embedded modules: Flask-SocketIO 5.6.1, python-socketio 5.16.3,
  python-engineio 4.13.3, simple-websocket 1.1.0 (MIT), bidict 0.23.1
  (MPL-2.0). Exact archives/checksums are included. Existing Socket.IO 4 /
  Engine.IO 3 ports cannot implement the protocol required here and have
  other consumers; they were neither replaced nor globally shadowed.
- Test-only: pytest; optional GUI tests also require pytest-qt and a display.
- Optional/disabled: bridge transports are discovered only when installed;
  eventlet is excluded because the backend explicitly uses gevent. Redundant
  setuptools/wheel/Cython/pkgconfig runtime requirements were removed.
- New dependency ports: none. Uncertain: current OpenBSD gevent and PySide
  compatibility, Tor bridge behavior, and actual privacy/runtime semantics.

The vendor script rewrites imports into onionshare_cli._vendor, including
dynamic Engine.IO transport discovery, and checks the result with Python's
AST. It does not create a custom Python environment or modify sys.path.
Patches use LOCALBASE Tor/geoip paths; absent pluggable transports do not
silently disable requested bridge mode. Metadata constraints were adjusted
where the current ports provide the same API (Stem, QRCode, Flask-Compress,
gevent, Python/PySide); this needs native confirmation, especially gevent.

Linux: both wheels built; 260 CLI tests passed, five skipped, three warnings;
49 offscreen GUI tests passed with Python 3.14 and PySide6 6.11.2. Linux
gevent was 26.8 rather than OpenBSD's inspected 24.11.1. An attempt to build
the older gevent in the temporary environment lacked Fedora Python headers;
the immutable host was not modified to work around this. GUI tests are not
silently treated as normal headless package tests.

Native: CLI tests, optional Tor tests (`pytest --runtor`), GUI tests in a
display session, all four modes, authenticated/public shares, symlinks,
receive permissions, Tor shutdown/cleanup and every requested bridge type.
Run as an ordinary user. OnionShare launches its own instance of the system
Tor executable with private state; do not enable tor's rc service solely
for this application. Do not rely on the untested port for privacy yet.

## Mullvad CLI and daemon

[Upstream 2026.4](https://github.com/mullvad/mullvadvpn-app/tree/2026.4),
GPL-3.0-or-later, Rust >=1.95. See [the dependency graph](net/mullvad/DEPENDENCIES.md)
and [the detailed native-backend report](net/mullvad/OPENBSD.md).

The CLI's seven internal crates exclude the daemon and GUI. The daemon
adds substantial native networking requirements; a successful RPC-client
build is not a VPN implementation. One multi-package port shares source,
lockfile and vendoring infrastructure. Default pseudo-flavor no_daemon
builds only the CLI; requesting the daemon retains an explicit BROKEN guard.
No GUI, Electron, mobile application, installer or update-service binary
is built. No root daemon, PF rule or resolver mutation is installed by the
default package.

Dependency classification: base Rust/C runtime and native kernel interfaces;
existing Rust infrastructure and build-only protobuf compiler; 616 pinned
registry crates via MODCARGO; exact private udp-over-tcp git revision
`5c6d8f44a5aa12ed9bb4ae51dd17e5e22e5ec303` as a second source archive.
No standalone crate ports or bundled system OpenSSL/DBus. Alternative-target
and test dependencies remain in the projected lock, not in WANTLIB.
Linux netlink/nftables/DBus/cgroup crates are target-excluded. New private
talpid-openbsd is backend groundwork, not another dependency port.

Linux: CLI release build passed; selected platform-neutral suites passed
48 tests with four upstream ignores, including seven new primitive tests.
OpenBSD cross-check was attempted but the installed Rust toolchain lacks
the target core/std sysroot (E0463). It did not validate OpenBSD compilation.
Native daemon build and RPC/login/tunnel/routing/PF/DNS/reconnection remain
unverified or blocked, as detailed in the subsystem report.

## Static validation and remaining native work

All 793 distfile SHA256 values and sizes were verified against downloaded
bytes. All 40 source patches apply to pristine selected releases without
fuzz or offset. Makefile continuations, Python AST/TOML, shell launchers,
package inventories, source/license metadata and explicit dependency paths
were reviewed. Recursive platform-API searches were followed by inspection
of selected code paths, not mechanical changes to every Linux match.
Cargo/Go use the current ports offline facilities; Python wheel builds use
preinstalled backends and no isolation; no submodule update, FetchContent,
pip/npm download or git clone occurs in a proposed build phase.

An additional Linux preparation check reconstructed both Rust vendor trees
offline from the checksumed archives, then resolved the OpenBSD-targeted
metadata with empty Cargo homes and no registry/network access. This passed
for both msedit and the projected Mullvad workspace. It validates source
closure, not native compilation; cargo vendor is not run by either port.

Candidate WANTLIBs are source/link-derived, not results of native
port-lib-depends-check. Python PLISTs come from wheel inventories; game data
from the archive; other PLISTs from explicit install targets. All require
native update-plist, including bytecode, manuals and debug entries.

Use a complete, matching OpenBSD -current ports tree, placing these nine
directories in the corresponding categories. The WIP overlay alone is not
a buildable replacement for /usr/ports. For each viable port, from its
directory, run the following **on OpenBSD**, checking each result before
continuing (do not bypass BROKEN for doasedit or the Mullvad daemon):

```sh
make clean=all
make fetch
make checksum
make extract
make patch
make configure
make build
make test
make fake
make update-plist
make port-lib-depends-check
make package
make install
make deinstall
make clean
/usr/ports/infrastructure/bin/portcheck -N
```

For Mullvad's current CLI candidate, keep the default no_daemon flavor.
For multi-packages, also check each subpackage's runtime dependencies and
installation/deinstallation separately. AssaultCube's redistribution
restriction is intentional and must not be overridden for distribution.
Apply the per-target runtime tests above in addition to this build sequence.
Mullvad's future privileged integration requires its separate safety-gated
test plan, not merely a successful package build.

## sdwdate: native OpenBSD adaptation (2026-09-06)

Status: **REQUIRES_OPENBSD_RUNTIME_WORK**. Source-level implementation and
offline tests exist; no OpenBSD build, Tor runtime, privilege transition or
clock-setting test has run. Do not interpret this as production readiness.

Source: [Kicksecure/sdwdate tag 29.0-1](https://github.com/Kicksecure/sdwdate/tree/29.0-1),
peeled commit `b420a67339bf5ba2ac39ec387b3b46d3c769d67d`, dated 2026-08-25.
This is a numbered release, not a moving master snapshot. Package version
`sdwdate-29.0.1` represents upstream's `29.0-1`. The tag archive is 202453
bytes; SHA256 is
`9ea57d544e0caa868db34792ad0b0ae0e954b90ca9ada60dfb54112e819a3b6e`.
`COPYING` declares AGPL-3.0-or-later and is the installed main-software license.
No third-party notice collection or upstream repository README is installed.

Neither the overlay nor the inspected official tree contains sdwdate.
`net/sdwdate` follows the network time-service/Tor category. The upstream
layout is distribution-oriented: no pyproject/setup metadata, no shared C
library, no submodules or build-time dependency fetch. `lang/python` supplies
the interpreter dependency and substitutions; private modules are installed
under `libexec/sdwdate`, without a custom Python environment or pip build.
Both C executables are compiled at port build time. No compiler or source
tree is installed for package-install-time compilation.

### Dependency closure and removed distribution glue

| Dependency/import | Importing component and purpose | Classification/decision |
| --- | --- | --- |
| Python 3 | All Python commands and modules | Existing `lang/python/3`, selected by module |
| `requests` | `openbsd.fetch_date`, called by url_to_unixtime | Existing `www/py-requests`, mandatory |
| `socks` | requests/urllib3 SOCKS adapter, not a direct sdwdate import | Existing `net/py-socks`, mandatory |
| `stem.control`, `.connection`, `.socket` | Tor readiness, SAFECOOKIE, consensus dates | Existing `net/py-stem`, mandatory |
| `dateutil.parser` | Tor consensus timestamp conversion | Existing `devel/py-dateutil`, mandatory |
| Tor | SOCKS onion transport and consensus/control service | Existing `net/tor`, mandatory |
| stdlib datetime/email/ssl/socket/threading/concurrent.futures/subprocess/pathlib/logging/json/html/re/secrets/random | Parsing, concurrency, source selection, state, logging | Python/base facilities, no new ports |
| `sdnotify` | Upstream systemd status/watchdog | Not selected by native entry point; initialization moved out of module import |
| `guimessages.translations` | GUI-oriented English/YAML translation loader | Not selected; small plain-English status map for terminal service |
| `sanitize_string` | Remove GUI markup/control characters for logging | Replaced by small stdlib HTML/control-character sanitizer |
| helper-scripts `onion-time-pre-script` | Wait for usable Tor/bootstrap environment | Native authenticated `status/circuit-established` check |
| helper-scripts `minimum-unixtime-show` | Replay lower bound | Release-date floor plus atomic persistent checkpoint |
| helper-scripts `settings_echo` | Whonix gateway discovery | Not applicable; explicit local Tor IP/port config |
| privleap/leaprun | Start/stop service, dispatch Python, touch step flag, hwclock | rc.d and private C broker; no privleap/doas dependency |
| gcc/libc-dev | Debian install-time compilation | OpenBSD base compiler, build-only |
| bc, util-linux-extra/hwclock | Distribution wrappers/RTC glue | Not used by native entry point; no added runtime port |
| adduser, systemd, tmpfiles/sysusers, rsyslog, AppArmor, Qubes hooks | Distribution integration | Excluded; PLIST accounts/directories, rc.d, syslog |
| timesanitycheck package, bootclockrandomization | Recommended ecosystem packages | Optional, not required and not ported |
| unittest, C assertions | Offline regression tests | Base/interpreter test-only; no extra test framework |

No dependency ports and no third-party vendored libraries were added. Ordinary
transitive requests/dateutil dependencies remain managed by their existing
ports. Linux-native venv tooling was temporary analysis equipment, never part
of the proposed OpenBSD package/build.

Recursive source/import and distribution-command inspection covered all 75
upstream files, including wrappers, privleap actions, the full Python daemon,
pool config, C helper, Debian metadata, generated manual and license.
Linux/systemd strings left in the imported upstream module belong to its
unused distribution entry point/methods; the installed daemon enters
`sdwdate.openbsd`, reuses only its pool/fetch/median/random-sleep logic and
does not call those methods. The original Debian command wrappers, service
units, src-install hooks, GUI, clock-jump/log-viewer wrappers and systemcheck
integration are not installed. The generic upstream code remains recognizable
instead of duplicating the entire selection engine.

### Tor and clock privilege boundary

```text
onion HTTP Date -> local Tor SOCKS -> _sdwdate Python
                       |                  |
              SAFECOOKIE consensus       +-- upstream three pools/median
                                          |
                           inherited SOCK_SEQPACKET (fd 3)
                                          |
                                  root C clock broker
                                          |
                                   CLOCK_REALTIME
```

Tor's existing package installs `${LOCALBASE}/bin/tor`, runs as `_tor:566`,
uses `/var/tor` mode 0700 and service `tor`. Control access is not enabled by
default. The package README gives explicit administrator configuration for
loopback ControlPort 9051 and a separate
`/var/run/tor-sdwdate/control.authcookie` in a `_tor:_tor` 0750 directory,
with CookieAuthentication and group readability. `/var/tor` stays private.
The native child gets exactly `_sdwdate` and `_tor` supplementary groups;
there is no world-readable cookie or NULL/password-prompt authentication.
SAFECOOKIE is mandatory; its verified protocol implementation remains Stem.
This grants full Tor-control authority, not read-only access. A separate Tor
instance is advisable where that authority is inappropriate for a shared Tor.
The package does not modify torrc or create its cookie directory silently.

SOCKS endpoints must be loopback IP literals. All time URLs must be HTTP(S)
v3 onion names, including valid subdomains. requests uses explicit socks5h
for both schemes, `trust_env=False`, streaming header-only responses,
connect/read deadlines, no redirects and unchanged HTTPS certificate checks.
Missing/duplicate/oversized/control-containing Date headers, non-2xx replies,
non-UTC dates and out-of-range timestamps fail explicitly. Responses and
sessions are closed. The standard email date parser replaces permissive
dateutil HTTP parsing; consensus parsing still uses dateutil and explicit UTC,
not nonportable `strftime('%s')`. No clearnet or unauthenticated fallback.
Per-fetch elapsed measurement uses monotonic time; remote-time comparison
retains real time. HTTP subprocess arguments are lists, not shell strings.

The public daemon `${PREFIX}/sbin/sdwdate` is the C parent, invoked by root,
never setuid. It creates a private socketpair, forks, drops all child UID/GID
identities, resets supplementary groups, sanitizes exec environment, excludes
the writable working directory from Python's import path (`-P`), closes
unneeded descriptors and execs the absolute Python interpreter/module path.
The broker descriptor is non-inheritable before HTTP subprocess creation.
No external user can connect: there is no pathname/socket listener.
The root process keeps no network connection, Python interpreter or generic
exec operation after startup. It chroots to `/var/empty` and locks unveil.
Its root-owned flock file prevents concurrent daemon instances.

Only ASCII `J <nanoseconds>` or `A <nanoseconds>` records are accepted, with
complete numeric conversion, size/NUL/overflow/range checks. J is allowed
only for the first accepted request and never with `--slew-only`; magnitude
is limited to 24 hours. A is limited to 30 seconds and applied in at most
5ms increments separated by at least one monotonic second. No catch-up burst,
accumulation of queued requests, shell command, arbitrary clock ID, filesystem
path or generic root operation is exposed. A request is acknowledged only on
completion; system-call failure is an explicit error and stops the broker.
Rate limiting also rejects requests less than 60 seconds apart. Dry-run has
the same input policy but executes no clock mutation.

The finite slew limit is a documented native policy, not an upstream promise:
larger gradual corrections fail rather than silently becoming clock steps.
At 5ms/second, the maximum allowed slew needs about 100 minutes. This first
adaptation waits for completion before the next randomized query interval;
upstream runs the helper in the background while sleeping. Security/selection
semantics are preserved, but query cadence is consequently longer during a
large gradual correction. Initial HTTPS/Tor bootstrap with a very wrong clock
remains an explicit limitation; manually repair it rather than weaken TLS.

SIGTERM cancels pending increments, terminates the unprivileged process group
and waits a bounded interval before SIGKILL. EOF cancels increments; a Python
monitor detects parent death even during sleep. Already applied time changes
cannot be undone. Native orphan/subprocess, exit-status and rc.d race testing
is required. The checkpoint is atomically replaced/fsynced after successful
completion only, has a release-date floor (2026-08-25) and retains upstream's
2033 upper bound. It is writable by the time-selection process, not a defense
against compromise of that process. The broker independently enforces bounds.

### C helper and hardening findings

Upstream used unchecked atoll, llabs on a potentially minimum signed value,
an unsigned iteration counter, whole-epoch nanosecond multiplication and
un-normalized negative remainders. The per-file sclockadj patch supplies
checked strtoimax parsing, bounded offsets, overflow-checked seconds arithmetic,
normalized nanoseconds, a signed remaining-offset loop and interrupt-aware
nanosleep. Zero is a valid no-op. Its arithmetic is compiled into the broker
and into the private standalone `${PREFIX}/libexec/sdwdate/sclockadj` utility;
neither executable has setuid permissions. The standalone helper likewise
rejects adjustments beyond 30 seconds. No compiler is needed after install.

`clock_settime` is not available under a pledge promise; even adjtime mutation
is prohibited after pledge (see [pledge(2)](https://man.openbsd.org/pledge.2)).
Do not invent a `settime` promise. Thus the parent uses chroot/unveil and a
small validated interface, but is not pledged. Python pledge/unveil is
deferred until actual interpreter/extension/config/CA/control/subprocess paths
have been traced natively. No broad speculative promise string is supplied.
Privilege dropping and fd/environment restrictions are statically implemented,
not claimed tested on OpenBSD. Securelevel restrictions and RTC persistence
after clock_settime must be tested there.

### Packaging, tests and remaining work

The account `_sdwdate:909` is registered in the overlay's user.list; it must
still be reconciled with the target tree's current allocation. fetch-ports
merges only overlay-owned account entries and rejects allocation conflicts.
PLIST declares mode-0700 `/var/db/sdwdate` and `/var/run/sdwdate`, configuration
samples under `share/examples/sdwdate`, and service `sdwdate`. The rc script
recreates runtime state, refuses symlinked directories and active ntpd, and
does not silently edit rc.conf.local or stop/disable ntpd. It cannot stop a
second clock daemon being started later. Direct invocation requires the
administrator to check that conflict explicitly.

The package installs only sdwdate, private sclockadj, url_to_unixtime, private
modules, a native mdoc manual, configuration samples and main license. The
generated upstream manual describes sudo, /run/pid and automatic startup;
using a short accurate OpenBSD manual avoids shipping those false directions
or adding Ruby/ronn solely for regeneration. Logs use syslog and stderr;
detailed upstream fetch diagnostics remain stdout for foreground debugging.
No file-log rotation, journals, systemd files or daemon PID file are added.

Linux checks completed: archive/checksum verification, eleven offline Python
unittests (HTTP mock policy/malformed headers, URL validation, layered config,
checkpoint, UTC consensus parsing, original median, original three pools,
successful/all-failed pool aggregation and mocked randomized sleep),
C builds with `-Wall -Wextra -Werror`, clock arithmetic/input assertions with
clock-setting code excluded, and socketpair broker framing/policy tests with
every broker hard-coded dry-run. These tests perform no host clock mutation,
root transition or real onion query. Upstream's extensive external dist-ai
suite was not claimed run. Added tests are part of `do-test`, not runtime
dependencies. There are seven single-file source patches, each with SPDX and
Index; new native files are ordinary port `files/` assets.

The Linux broker compilation additionally uses `-D_GNU_SOURCE` to expose
glibc's setresuid/setresgid declarations. This analysis-only flag is not added
to the OpenBSD port; OpenBSD declares these APIs without a GNU feature macro.

Before enabling on a real machine: run the complete ports sequence in the
preceding section for `/usr/ports/net/sdwdate`, including update-plist and
port-lib-depends-check. Candidate WANTLIB is only libc, derived from the two
C executables; Python/Tor libraries are runtime dependencies, not speculative
link entries. Validate account collisions, all installed paths and substitutions,
manual syntax, rc.d matching, file ownership and no bytecode/build artifacts.

Then follow `net/sdwdate/pkg/README`: verify Tor/cookie bootstrap first;
use `sdwdate --dry-run --once`, then rc.d with `--dry-run`. Check `rcctl check
ntpd`, `rcctl check tor`, `rcctl check sdwdate`, `ps aux`, `fstat -p PID`,
`netstat -an -f unix`, ownership and syslog. `sockstat` is not OpenBSD base.
Exercise unavailable/bootstrap/reconnecting Tor, bad control auth, hung control
socket, malformed sources, partial/all-source failure, config/checkpoint errors,
startup/stop/restart and ntpd conflict. Only in a disposable OpenBSD VM with
ntpd deliberately stopped: positive/negative correction, initial step versus
--slew-only, gradual correction, excessive offset, securelevel rejection,
parent SIGKILL, child death, reboot and RTC/checkpoint persistence. No native
clock, Tor-control, sandbox or reboot behavior is marked IMPLEMENTED merely
because the Linux offline tests passed.

Additional checks: mandoc reports no syntax warnings for the native manual
(the referenced OpenBSD manuals are absent on Fedora). The dry-run broker
tests also reject oversized packets and repeated corrections, with child
watchdogs bounding failures. An optional UBSan build could not link because
the available toolchain lacks its libubsan runtime; no sanitizer success is
claimed and no host packages were installed to change that. An independent
128-bit arithmetic oracle matched 100000 deterministic boundary/random cases
of the pure clock arithmetic, including signed limits and negative nanoseconds.

## SimpleX and copy-helper follow-up

See `net/simplexmq/TEST-FAILURES.md` for the original nine-failure map,
reproduced TLS framing/consumer lifetime defects, HTTP/2 compatibility fix,
Linux repetitions, actual full-suite result, unresolved native hypotheses
and exact OpenBSD commands. Shared fixes are mirrored in simplex-chat.

All 191 port/dependency patches have SPDX-License-Identifier, Index and one
target file. The overlay currently contains 24 category/port paths.
fetch-ports was exercised in temporary checkouts for complete/selected copies,
CVS preservation, sibling preservation, readable build-user permissions,
backups, traversal/symlink rejection and user-registry conflicts/preservation.
No host provisioning workflow was run. The corresponding fetch-src changes
in ../wip-openbsd-src map pax to src/bin/pax and fvwm to xenocara/app/fvwm;
both copy paths and failure checks were exercised. Both scripts pass ksh
syntax and shellcheck. BUILDING.md and that repository's FETCHING.md document
the non-provisioning --copy-only operation and its limitations.
