# Initial OpenBSD ports status

Source review: 2026-09-05. Development host: Fedora Atomic (Linux).
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
