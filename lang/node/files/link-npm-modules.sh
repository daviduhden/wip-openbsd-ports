#!/bin/sh
# Move npm's npm/node_modules entries up two levels and replace them with
# symlinks, matching npm's expected installation layout.

set -eu

: "${PREFIX:?}"

directory="$PREFIX/lib/node_modules/npm/node_modules"
[ -d "$directory" ] || {
	echo "missing npm module directory: $directory" >&2
	exit 1
}

cd "$directory"
for module in *; do
	[ -e "$module" ] || continue
	mv "$module" ../..
	ln -s "../../$module" "$module"
done
