# Building and Testing These Ports on OpenBSD

This repository carries custom OpenBSD ports for:

- `net/monero`
- `net/xd-torrent`

The working copies in this repository are meant to be copied into `/usr/ports/net/`
or kept in sync with the same layout there.

## Prerequisites

Configure the ports tree in the usual OpenBSD way:

- set `WRKOBJDIR`
- set `DISTDIR`
- set `PACKAGE_REPOSITORY`
- use `doas` or `sudo` as your privilege helper

The repository includes `fetch-ports.ksh` to bootstrap a ports tree and copy the
custom ports into place under `/usr/ports/net/`.

For the SimpleX ports, `sync-simplex-ports.pl` helps keep the shared Hackage
pins in sync and normalizes `patches/` filenames so they follow the OpenBSD
path-based convention.

Examples:

```sh
perl ./sync-simplex-ports.pl list-deps
perl ./sync-simplex-ports.pl --apply all
```

## General Workflow

From the port directory:

```sh
make clean
make fetch
make makesum
make patch
make configure
make build
make fake
make update-plist
make port-lib-depends-check
make package
```

Not every target is always useful for every port, but this is the standard order
when you are refreshing or validating a port.

## Monero

The Monero port is a CMake-based C++ port.

Recommended workflow:

```sh
cd /usr/ports/net/monero
make clean
make fetch
make makesum
make patch
make configure
make build
make fake
make update-plist
make port-lib-depends-check
make package
```

Notes:

- `make configure` is the first useful gate for CMake dependency problems.
- `make port-lib-depends-check` catches missing or extra shared-library deps.
- `make update-plist` should be run after `fake` whenever installed files change.
- The current OpenBSD port disables Monero stack-trace detection via the
  `DEPENDS` CMake path, so `configure` should not try to resolve a standalone
  `libunwind` package on this tree.

## XD Torrent

The XD torrent port is a Go port and uses `modules.inc` for vendored module
metadata.

Recommended workflow:

```sh
cd /usr/ports/net/xd-torrent
make clean
make fetch
make makesum
make patch
make configure
make build
make fake
make update-plist
make port-lib-depends-check
make package
```

When upstream `go.mod` or `go.sum` changes:

```sh
make modgo-gen-modules > modules.inc
make makesum
```

Notes:

- `modules.inc` is the file that records the module list and replacement
  module hashes used by the OpenBSD Go ports infrastructure.
- `make port-lib-depends-check` is still worth running because the final binary
  may link against native libraries even when the source is Go.
- `make update-plist` is needed if the binary set or installed symlinks change.

## Practical Validation

After packaging, the important checks are:

1. `make update-plist` if the installed file list changed.
2. `make port-lib-depends-check` if shared-library dependencies changed.
3. `make package` to verify the final package assembly.

For a quick smoke test, install the package and run the main binaries manually.
For Monero, that usually means starting `monerod` or checking the CLI binaries.
For XD, confirm that `XD` and the `XD-CLI` symlink are present and start with a
known config file.
