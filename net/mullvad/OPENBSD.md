# Mullvad 2026.4: native OpenBSD development status

Overall: **REQUIRES_OPENBSD_RUNTIME_WORK**. CLI packaging is prepared;
the daemon is **BLOCKED**, not a functional VPN. Everything described as
STATICALLY_IMPLEMENTED below still requires native compilation/testing.
No network configuration was changed on the Fedora analysis host.

## Architecture and dependency closure

The upstream management protocol is preserved: `mullvad` is an RPC client;
`mullvad-daemon` remains the privileged backend. The CLI cannot create a
tunnel on its own, and does not expose a remote TCP-daemon transport.

```text
mullvad-cli (7 internal crates, including itself)
    -> management RPC over Unix socket
mullvad-daemon (26 internal crates, including itself)
    -> account/device/settings/relay/API logic
    -> talpid-core state machine
        -> tunnel -> gotatun -> tun device
        -> routing -> native OpenBSD route backend [incomplete]
        -> firewall -> PF backend [incomplete]
        -> DNS -> resolvd lifecycle [incomplete]
        -> offline monitor / reconnect [incomplete]
```

[DEPENDENCIES.md](DEPENDENCIES.md) gives normal/build internal adjacency,
shared crates and target comparisons. Before port-specific additions,
OpenBSD metadata resolves 221 CLI packages and 387 daemon packages, sharing
218. Internal shared crates are intersection-derive,
mullvad-management-interface, mullvad-paths, mullvad-types, mullvad-version,
talpid-types. Union: 27 internal crates, not the entire workspace.
talpid-openbsd is a new development-only internal crate.

Feature-aware analysis was repeated independently with cargo tree for the
CLI and daemon. The graph report uses target-filtered metadata and excludes
dev-only edges; metadata workspace feature unification can overestimate
features, so use both methods. Reproduce during source preparation:

```sh
cargo metadata --locked --format-version 1 \
    --filter-platform x86_64-unknown-openbsd > metadata-openbsd.json
python3 audit-closure.py metadata-openbsd.json
cargo tree --locked -p mullvad-cli --no-default-features \
    --target x86_64-unknown-openbsd --edges normal,build -f '{p} {f}'
cargo tree --locked -p mullvad-daemon --no-default-features \
    --target x86_64-unknown-openbsd --edges normal,build -f '{p} {f}'
```

`audit-closure.py` is in files/; run these outside a package build when
resolving new releases. Port builds use the supplied lock and offline
MODCARGO configuration. Linux, Windows, macOS and Android target graphs
were also inspected. iOS applications are not a deliverable or a daemon
target; their application workspaces/frameworks are excluded, rather than
misrepresented as required daemon dependencies.

### Selected dependency classes

- Portable/generic Unix: serde/prost/tonic protocol and settings types,
  clap, Tokio/mio/kqueue, tipsy Unix sockets, account/API/relay logic,
  ring/rustls and platform-neutral cryptography. Generic Unix does not imply
  the encompassing daemon is already portable.
- Linux-specific, excluded for OpenBSD: talpid-cgroup, talpid-dbus,
  talpid-net Linux paths, rtnetlink/netlink crates, nftnl/mnl, DBus/inotify,
  Linux default jemalloc allocator, fwmark and namespace facilities.
- Windows-only: talpid-windows, WFP/Wintun/service/registry/installer APIs.
  macOS-only: talpid-macos, NetworkExtension/SystemConfiguration,
  Objective-C frameworks, Darwin PF bindings. These are not OpenBSD backends.
- Android-only: JNI/jnix/ndk/application plumbing. No mobile application,
  Electron, GUI, installers, or updater executable is built.
- Missing native implementation: tun crate OpenBSD device support,
  talpid-routing, firewall state ownership, DNS lifecycle, connectivity
  monitor, split-tunnel selection and leak-checker transport.

The daemon's 2026.4 user-space WireGuard engine is **gotatun 0.8.1**, with
device/tun and DAITA features; its tun dependency is 0.8.14. The current
desktop path is not wireguard-go. tun supports FreeBSD but has no OpenBSD
platform module. Linux can also use a kernel backend. OpenBSD wg(4) is a
possible different design, but substituting it would require adapting
Mullvad's tunnel abstraction and reviewing DAITA/obfuscation semantics.
The initial approach retains the existing engine and localizes device work.

616 registry archives are pinned by the projected Cargo.lock/crates.inc;
the count includes alternative-target and test resolution, not 616 linked
libraries. udp-over-tcp is a private path dependency at upstream git revision
5c6d8f44a5aa12ed9bb4ae51dd17e5e22e5ec303, provided as a checksumed distfile.
No language dependency ports are introduced. Build.rs review identified
protoc for the management schema, C/assembly toolchain work in ring, and
the native C bridge. No OpenBSD-selected libdbus, BoringSSL, CMake, bindgen
or libclang requirement is added speculatively. Native build must confirm
the remaining cryptographic/tunnel crate assumptions.

## Packaging and changes already prepared

One net/mullvad multi-package source avoids two Cargo vendoring systems.
Default pseudo-flavor `no_daemon` builds only mullvad-cli. `FLAVOR=""`
selects the daemon too but is guarded by BROKEN; do not override that guard
merely to claim an installable VPN. Both deliverables use upstream 2026.4.

Source patches prune the root workspace to the needed union, pin the git
dependency locally, recognize OpenBSD in version/platform metadata, avoid
git version probes when MULLVAD_BUILD_FROM_ARCHIVE=1, fix a cfg-dependent
daemon CLI type inference issue, gate unsupported split-tunnel CLI commands,
enable Unix termination handling and use OpenBSD's suspend-inclusive clock.
The IPv6 interface path now uses a fixed /sbin/ifconfig argv with checked
exit status on OpenBSD, rather than silently compiling out the operation.
That is initial technical debt, not a complete tunnel provider.

Mullvad's in-app upgrade cfg is not enabled for OpenBSD. Version polling
has an explicit OpenBSD false gate: there is no matching signed platform
manifest. mullvad-update remains in the library closure for protocol/types,
not as a package self-updater. OpenBSD packages must manage upgrades.

Potentially upstreamable patches: correct OpenBSD cfg/paths/clock handling,
archive version metadata, opt-in restrictive Unix socket policy and the
eventual small native platform modules. The projected packaging workspace
and BROKEN guards are ports maintenance, not proposed upstream architecture.

## Platform subsystem audit

| Component / semantic purpose | Upstream mechanism | OpenBSD replacement | Current state |
| --- | --- | --- | --- |
| Tunnel packets and addresses | gotatun + Linux TUN ioctls; optional Linux kernel WG | /dev/tunN, native ioctls and AF framing | Framing codec STATICALLY_IMPLEMENTED; device/engine integration BLOCKED |
| Routes, endpoint bypass, restoration | rtnetlink, RPDB, fwmarks | AF_ROUTE messages, priorities, ownership journal | Read-only snapshot/event primitives STATICALLY_IMPLEMENTED; mutation BLOCKED |
| Kill switch and allowed traffic | nftables/mnl/netfilter rules and marks | verified dedicated PF anchor and state management | Candidate blocked-policy renderer PARTIAL; loader/connected policy BLOCKED |
| DNS lifecycle | resolved, NetworkManager, resolvconf/static file mechanisms | RTM_PROPOSAL + resolvd integration, PF enforcement | Proposal/withdraw primitive STATICALLY_IMPLEMENTED; lifecycle BLOCKED |
| Network changes | netlink/DBus notifications | AF_ROUTE + kqueue/AsyncFd, snapshot reconciliation | Socket creation STATICALLY_IMPLEMENTED; monitor integration BLOCKED |
| Interface/routing binding | SO_MARK, SO_BINDTODEVICE, per-process bypass | owned physical endpoint routes or reviewed SO_RTABLE design | Design only; not success-returning emulation |
| Split tunneling | cgroups/netns or platform process filtering | separate routing/security design | Not required for initial feature set; CLI operation excluded; daemon selection incomplete |
| Leak checker | OS-specific traceroute/packet transport | native socket/route selection and verified capture behavior | BLOCKED; unavailable must never mean NoLeak |
| API/account/device/relay/settings | Rust HTTPS/state/protocol logic | existing portable logic | Source retained; runtime depends on completing daemon startup |
| Desktop integration | systemd, GUI helpers, installers, mobile frameworks | rc.d only when safe | Unrelated components excluded; rc candidate refuses startup |

### Tunnel and routes

The framing codec handles both OpenBSD AF_INET=2 and AF_INET6=24 in a
four-byte network-order header; malformed/truncated packets are rejected.
Device allocation, MTU, IPv4/IPv6 addresses, descriptor ownership and
asynchronous readiness still need a real tun platform module. Do not copy
FreeBSD or Darwin ioctl numbers into an OpenBSD compatibility facade.
Review [tun(4)](https://man.openbsd.org/tun.4) for device creation and
last-close behavior; interface lifetime is part of recovery, not just I/O.

native.c uses native OpenBSD headers for AF_ROUTE sockets and a NET_RT_DUMP
sysctl snapshot; no kernel struct layouts are guessed in Rust. The monitor
descriptor is nonblocking/CLOEXEC and suitable for AsyncFd/kqueue. Subscribe
before snapshotting, validate every variable-length message, process both
families, and resnapshot under a blocked policy after RTM_DESYNC/read errors.
No route output parser or mutating route command was added.

The missing route manager must own only its routes: journal additions with
family/table/priority/interface/gateway identity, match acknowledgements by
sequence, detect external changes, and never remove somebody else's route
because a destination prefix happens to match. Restore in reverse dependency
order after errors/crashes. Link-local IPv6 gateways need scope preservation.
The current primitive targets rtable 0; arbitrary rdomains are unsupported.
The ABI/event basis is [route(4)](https://man.openbsd.org/route.4).

Linux marks exist to keep API/relay transport outside the tunnel while
routing application traffic inside it. A candidate OpenBSD design installs
owned endpoint-specific physical routes before tunnel routes and uses PF
to restrict those exceptions. SO_RTABLE is an alternative requiring a
separate analysis of resolver and socket lifetimes. Neither design has
been implemented; no SO_MARK/SO_BINDTODEVICE wrapper returns fake success.

### PF security gate

A named anchor alone is not a kill switch. Earlier quick rules, skipped
interfaces, pre-existing floating states and external PF reloads can all
defeat a superficially correct child ruleset. The candidate renderer covers
only blocked/connecting exceptions (loopback, DHCP/NDP, numeric privileged
endpoints) and a final block. It does not implement the connected policy,
LAN exceptions, DNS restrictions or state revocation. No loader is exposed.
The talpid-core OpenBSD boundary returns explicit errors for construction,
apply and reset; this is a refusal, not packet filtering.

Proposed integration: an administrator-approved dedicated `mullvad` anchor,
reachable before permissive quick rules, with scoped children for policy
and endpoint tables. Verify PF enabled, anchor ordering and skip settings
through native ioctl inspection; reject incompatible configurations. Never
rewrite the full /etc/pf.conf. Use an atomic anchor ruleset transaction;
failed changes leave the previous blocking policy intact. Native pfctl
with fixed argv/stdin may be an initial loader, but parsing human-oriented
output to certify security is inadequate.

Anchor rules can persist after daemon death; do not flush them automatically
on a crash. A secure boot/reload policy must restore a blocking anchor before
ordinary traffic, and refuse connection if the parent anchor disappeared.
Existing states need a reviewed revocation policy: killing only newly
labelled Mullvad states cannot revoke arbitrary pre-existing bypass states,
while a global state flush damages unrelated networking. This is a major
unresolved compatibility/security constraint, not a minor TODO.

PF review references: [pf(4)](https://man.openbsd.org/pf.4),
[pf.conf(5)](https://man.openbsd.org/pf.conf.5),
[pfctl(8)](https://man.openbsd.org/pfctl.8), and upstream
[security policy](https://github.com/mullvad/mullvadvpn-app/blob/2026.4/docs/security.md).

### Resolver lifecycle

DnsProposal publishes numeric IPv4/IPv6 addresses with RTM_PROPOSAL,
RTA_DNS and static proposal priority. Empty lists withdraw both families.
Both messages are attempted on errors; no two-message transaction or
resolvd acknowledgement is claimed. Publication is not proof of DNS safety.
It never writes /etc/resolv.conf. Inputs reject malformed interface names,
unspecified/multicast/loopback and unsupported scoped DNS addresses.

resolvd combines proposals from networking daemons; unwind can take resolver
precedence, and administrator-supplied nameservers can remain. A VPN proposal
therefore cannot by itself exclude fallback DNS. The integration must keep
PF blocked while publishing, verify effective resolver behavior, restrict
DNS egress to the selected tunnel servers, and refuse unsupported unwind/
local-proxy configurations. On disconnect, withdraw only owned proposals
before releasing the interface; preserve PF blocking if restoration fails.
Handle resolvd restart and DHCP/SLAAC updates without continuously fighting
the base daemons. No speculative resolvd.conf interface is introduced.
See [resolvd(8)](https://man.openbsd.org/resolvd.8) and
[route(8) nameserver](https://man.openbsd.org/route.8).

### Privilege, IPC and service lifecycle

Upstream expects a privileged desktop daemon. Opening/configuring TUN,
route changes, PF ioctls, DNS proposals, recovery and reconnect require
privilege after initialization. The current architecture cannot simply
drop to an _mullvad user. No cosmetic account, speculative pledge/unveil,
chroot, or reduced-permission failure bypass is added.

A future privileged helper could hold narrowly scoped network descriptors
while an unprivileged worker handles API/state/RPC, but descriptor and
recovery requirements need to be established first. Ordinary users cannot
be granted partial RPC authorization merely by adjusting filesystem mode:
the management protocol has no per-operation authorization boundary.

The existing tonic/prost/tipsy protocol and Unix transport are retained.
OpenBSD socket creation is patched to start at mode 0600. Upstream's
MULLVAD_MANAGEMENT_SOCKET_GROUP explicitly permits a chosen group (0760);
that group gains account and privileged VPN control, not read-only status.
There is no world-writable fallback on OpenBSD. Native tests must check
ownership, stale socket handling, conflict errors and startup umask.
The daemon sets umask 077 before creating its runtime/threads, preventing
a permissive inherited umask from exposing the bind-to-chmod window in
tipsy's Unix listener implementation.

Candidate paths:

| Purpose | Path / policy |
| --- | --- |
| CLI | /usr/local/bin/mullvad |
| Daemon | /usr/local/sbin/mullvad-daemon, not installed by default |
| RPC | /var/run/mullvad-vpn; MULLVAD_RPC_SOCKET_PATH override |
| Persistent settings/account state | /var/db/mullvad-vpn; root-owned/private |
| Cache | /var/db/mullvad-vpn/cache; root-owned/private |
| Logs | /var/log/mullvad-vpn if daemon file logging is enabled |
| Read-only resources | /usr/local/share/mullvad; MULLVAD_RESOURCE_DIR |
| rc service | mullvad_daemon, future integration only |

files/mullvad_daemon.rc.candidate uses rc.subr conventions but is deliberately
not in pkg/ and refuses rc_pre. It must not be installed as a functional
service. No systemd files, launch agents, in-app updater, automatic login,
PF reload or daemon startup occurs during package installation.

## Security invariants and functionality

| Invariant | OpenBSD status |
| --- | --- |
| Kill switch / failure blocking | BLOCKED: startup refusal exists, operational filtering does not |
| Tunnel-only application routes | BLOCKED: route mutation/ownership incomplete |
| DNS leak prevention | BLOCKED: proposal primitive is insufficient |
| IPv6 leak prevention | BLOCKED: IPv6 is explicitly included in design/tests, not operational |
| Firewall restoration/crash persistence | BLOCKED: anchor/state/boot lifecycle incomplete |
| Route restoration | BLOCKED: ownership journal and mutation absent |
| Resolver restoration | BLOCKED: withdrawal primitive exists, lifecycle not integrated |
| Daemon socket access control | STATICALLY_IMPLEMENTED; REQUIRES_OPENBSD_TESTING |

| Function | Classification |
| --- | --- |
| CLI build/package source | STATICALLY_IMPLEMENTED; REQUIRES_OPENBSD_TESTING (Linux build passed) |
| Daemon build | BLOCKED by missing platform selections and native backends |
| RPC interoperability | PARTIAL: upstream transport retained, native daemon runtime unavailable |
| Login/device/account expiry/settings | PARTIAL: portable source retained, native runtime blocked |
| Relay/API retrieval and selection | PARTIAL: portable source retained, native runtime blocked |
| Bridges/custom DNS/obfuscation/DAITA | PARTIAL: settings retained, native transport enforcement blocked |
| Tunnel | BLOCKED; framing helper alone is not a tunnel |
| Routing | BLOCKED; read-only primitives alone do not route traffic |
| Firewall | BLOCKED; a candidate PF string is not enforcement |
| DNS | BLOCKED; a proposal is not leak protection |
| IPv6 | BLOCKED; not globally disabled to hide missing support |
| Reconnect/network changes | BLOCKED; event socket not integrated |

The upstream leak checker has a particularly important trap: some probe
errors are logged and converted into NoLeak. An unsupported OpenBSD probe
must not be introduced there as an error-only shim and then advertised as
successful leak checking. Make unavailable/unknown explicit or refuse the
feature until transport and interpretation have been reviewed.

## Achievable stages and native validation

1. Native CLI build and platform-neutral tests; close cfg/ABI issues without
   enabling the daemon. Verify strict socket behavior with a test server,
   never against an assumed working tunnel.
2. Finish tun device support and route parsing/ownership in isolated tests.
   Complete network-monitor and daemon platform selection. An account-only
   daemon is not currently implemented: startup initializes network state
   before the normal RPC lifecycle, so decoupling requires an explicit
   upstream-style mode, not successful no-op networking backends.
3. Implement and review PF enforcement/state/boot invariants before enabling
   traffic; then integrate native routes, tunnel and DNS under that block.
4. Add resolver/route/firewall journals, event reconciliation, leak-checker
   semantics and recovery for both families. Validate failure injection.
5. Only then remove BROKEN, install a real pkg rc script, run end-to-end
   account/VPN tests and reconsider package readiness.

Linux evidence: CLI release build succeeded; selected crate suites passed
48 tests with four upstream ignores, including seven new input/framing/PF
candidate tests. The new C bridge is compiled only on OpenBSD and remains
untested. `cargo check --target x86_64-unknown-openbsd` failed because this
Rust installation lacks the OpenBSD core/std sysroot (E0463). No ad-hoc
sysroot or Linux defines were used to manufacture success.

Run the normal ports sequence from the top-level status report on a real
OpenBSD -current machine. For additional isolated source tests after the
native prerequisites are satisfied:

```sh
cargo test --locked --offline -p mullvad-cli \
    -p mullvad-management-interface -p mullvad-types \
    -p mullvad-version -p talpid-types -p talpid-openbsd
```

Native kernel tests must use a disposable VM with console access, not the
SSH session carrying development access. First record unrelated rules,
routes, interfaces and resolver state. Once a functional daemon is enabled
by the reviewed implementation, the selected service commands will be:

```sh
rcctl enable mullvad_daemon
rcctl start mullvad_daemon
rcctl check mullvad_daemon
mullvad --help
doas mullvad status
```

These service commands are **not available/safe with the present candidate**.
Use an explicitly authorized test account for login/device operations; do
not embed credentials in scripts or publish account numbers in logs.
Confirm account login/logout/expiry, device registration/removal and relay
refresh separately from local networking. Then test connect/disconnect,
IPv4/IPv6 addresses/default routes, DNS, LAN exceptions, custom DNS and
supported obfuscation settings. Compare CLI state to kernel state, not just
the word Connected in RPC output.

Read-only native diagnostics during each transition include:

```sh
ifconfig -a
route -n get default
route -n get -inet6 default
netstat -rn -f inet
netstat -rn -f inet6
pfctl -sr
pfctl -a 'mullvad/*' -sr
pfctl -ss
pfctl -v -s Interfaces
rcctl check resolvd
rcctl check dhcpleased
rcctl check slaacd
ps -axo user,pid,ppid,command
fstat -u root
ls -ld /var/db/mullvad-vpn /var/run/mullvad-vpn
```

Use fstat/netstat for socket inspection; sockstat is not assumed to be an
OpenBSD base command. If separately available, it is supplementary only.
Use packet captures on both the physical and tunnel interfaces to test DNS
and IPv4/IPv6 traffic while disconnected/connecting/connected/blocked, with
both pre-existing and new TCP/UDP states. A browser IP-check alone is not a
kill-switch test.

Failure matrix: tunnel setup error, failed route acknowledgement, failed
PF transaction, missing parent anchor, skipped interface, stale PF states,
resolvd/unwind interactions, daemon TERM and abrupt crash, reconnect,
physical-interface removal, Wi-Fi/Ethernet switch, DHCP/SLAAC changes,
suspend/resume, full daemon restart and system reboot. Test recovery with
the tunnel unavailable. Verify unchanged unrelated PF rules, no unintended
global state flush, correct owned-route/proposal restoration and continued
blocking on uncertain state. These are completion gates, not tests already
performed on Fedora.
