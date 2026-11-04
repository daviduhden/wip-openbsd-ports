#!/bin/sh
# Prefix the installed utilities with uu- so they do not replace base tools.

set -eu

: "${PREFIX:?}"

[ -d "$PREFIX/bin" ] || {
	echo "missing binary directory: $PREFIX/bin" >&2
	exit 1
}

cd "$PREFIX/bin"
for program in *; do
	[ -e "$program" ] || continue
	mv "$program" "uu-$program"
done
