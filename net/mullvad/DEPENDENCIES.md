# Mullvad 2026.4 dependency graph

Generated from target-filtered Cargo metadata, following normal/build edges only.
The upstream default-feature graph is shown; the port disables the Linux-only
default allocator. Confirm selected features with the commands in OPENBSD.md.

| Target | CLI packages | Daemon packages | Shared packages |
| --- | ---: | ---: | ---: |
| openbsd | 221 | 387 | 218 |
| linux | 222 | 418 | 219 |
| windows | 220 | 425 | 218 |
| macos | 221 | 424 | 218 |
| android | 234 | 407 | 232 |

## OpenBSD cli internal adjacency

```text
intersection-derive -> (external crates only)
mullvad-cli -> mullvad-management-interface, mullvad-types, mullvad-version, talpid-types
mullvad-management-interface -> mullvad-paths, mullvad-types, talpid-types
mullvad-paths -> (external crates only)
mullvad-types -> intersection-derive, mullvad-version, talpid-types
mullvad-version -> (external crates only)
talpid-types -> (external crates only)
```

## OpenBSD daemon internal adjacency

```text
intersection-derive -> (external crates only)
mullvad-api -> mullvad-api-constants, mullvad-encrypted-dns-proxy, mullvad-fs, mullvad-types, mullvad-version, talpid-time, talpid-types
mullvad-api-constants -> (external crates only)
mullvad-daemon -> mullvad-api, mullvad-encrypted-dns-proxy, mullvad-fs, mullvad-leak-checker, mullvad-logging, mullvad-management-interface, mullvad-paths, mullvad-relay-selector, mullvad-types, mullvad-update, mullvad-version, talpid-core, talpid-dns, talpid-future, talpid-platform-metadata, talpid-routing, talpid-time, talpid-types
mullvad-encrypted-dns-proxy -> (external crates only)
mullvad-fs -> talpid-types
mullvad-leak-checker -> (external crates only)
mullvad-logging -> (external crates only)
mullvad-management-interface -> mullvad-paths, mullvad-types, talpid-types
mullvad-masque-proxy -> talpid-tunnel
mullvad-paths -> (external crates only)
mullvad-relay-selector -> mullvad-types, talpid-types
mullvad-types -> intersection-derive, mullvad-version, talpid-types
mullvad-update -> mullvad-api-constants, mullvad-version
mullvad-version -> (external crates only)
talpid-core -> talpid-dns, talpid-routing, talpid-tunnel, talpid-types, talpid-wireguard
talpid-dns -> talpid-types
talpid-future -> talpid-time
talpid-platform-metadata -> (external crates only)
talpid-routing -> talpid-types
talpid-time -> (external crates only)
talpid-tunnel -> talpid-routing, talpid-types
talpid-tunnel-config-client -> talpid-types
talpid-types -> (external crates only)
talpid-wireguard -> talpid-routing, talpid-tunnel, talpid-tunnel-config-client, talpid-types, tunnel-obfuscation
tunnel-obfuscation -> mullvad-masque-proxy, talpid-types
```

## OpenBSD shared internal adjacency

```text
intersection-derive -> (external crates only)
mullvad-management-interface -> mullvad-paths, mullvad-types, talpid-types
mullvad-paths -> (external crates only)
mullvad-types -> intersection-derive, mullvad-version, talpid-types
mullvad-version -> (external crates only)
talpid-types -> (external crates only)
```

## Additional selection: linux

Internal: talpid-cgroup, talpid-dbus, talpid-net

External package names (not all are intrinsically OS-specific):

ctrlc, dbus, home, inotify, inotify-sys, libdbus-sys, linux-raw-sys, mnl, mnl-sys, netlink-packet-core, netlink-packet-route, netlink-proto, netlink-sys, nftnl, nftnl-sys, paste, pkg-config, rs-release, rtnetlink, tikv-jemalloc-sys, tikv-jemallocator, tokio-tfo, triggered, which

## Additional selection: windows

Internal: talpid-windows

External package names (not all are intrinsically OS-specific):

anstyle-wincon, async-channel, async-task, blocking, concurrent-queue, csv, csv-core, ctrlc, event-listener, event-listener-strategy, futures-lite, ipconfig, libloading, once_cell_polyfill, parking, piper, tokio-tfo, toml, widestring, winapi, windows, windows-collections, windows-core, windows-future, windows-implement, windows-interface, windows-link, windows-numerics, windows-registry, windows-result, windows-service, windows-strings, windows-sys, windows-targets, windows-threading, windows_x86_64_msvc, winres, wintun-bindings, wmi

## Additional selection: macos

Internal: talpid-macos, talpid-net

External package names (not all are intrinsically OS-specific):

block2, core-foundation, core-foundation-sys, ctrlc, darling, darling_core, darling_macro, derive_builder, derive_builder_core, derive_builder_macro, dispatch2, fsevent-sys, hickory-server, ident_case, ioctl-sys, libloading, notify, notify-types, objc2, objc2-core-foundation, objc2-encode, objc2-foundation, objc2-security, objc2-service-management, pcap, pfctl, pkg-config, same-file, system-configuration, system-configuration-sys, tokio-tfo, walkdir

## Additional selection: android

Internal: (none in addition to the OpenBSD closure)

External package names (not all are intrinsically OS-specific):

android_system_properties, cesu8, combine, ctrlc, jni, jni-macros, jni-sys, jni-sys-macros, jnix, jnix-macros, linux-raw-sys, ndk-context, ndk-sys, paranoid-android, same-file, simd_cesu8, simdutf8, tokio-tfo, walkdir

The prepared source adds the internal talpid-openbsd development crate.
The exact udp-over-tcp git dependency becomes a pinned private path dependency.
Neither change adds a standalone dependency port. Alternative-target and
test resolution remains in Cargo.lock; presence there does not mean compilation.
