#!/bin/sh
# Apply the pinned Monero patches to the shared source tree.

set -eu

: "${MONERO_WRKSRC:?}" "${FILESDIR:?}"

for patch_name in $MONERO_PATCHES; do
	patch -d "$MONERO_WRKSRC" -p0 < "$FILESDIR/monero/$patch_name"
done
