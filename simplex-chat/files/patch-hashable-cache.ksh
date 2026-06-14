#!/bin/ksh
set -eu

tarball=${1:-}
patchfile=${2:-}
pkgdir=${3:-hashable-1.4.3.0}

[ -n "$tarball" ] || exit 0
[ -n "$patchfile" ] || exit 1
[ -f "$tarball" ] || exit 0
[ -f "$patchfile" ] || exit 1

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/hashable.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

tar -xzf "$tarball" -C "$tmpdir"

if grep -q 'os-string' "$tmpdir/$pkgdir/hashable.cabal"; then
	exit 0
fi

patch -d "$tmpdir" -p0 < "$patchfile"
tar -C "$tmpdir" -czf "$tarball.tmp" "$pkgdir"
mv "$tarball.tmp" "$tarball"
rm -rf "$tmpdir"
trap - EXIT HUP INT TERM
