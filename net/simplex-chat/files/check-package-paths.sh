#!/bin/sh
# Fail when a pinned Cabal package path is missing from the extracted tree.
# Usage: check-package-paths.sh PATH...

set -eu

for package_path in "$@"; do
	if [ ! -f "$package_path" ]; then
		echo "missing cabal package: $package_path" >&2
		exit 1
	fi
done
