#!/bin/sh
# Apply the pinned dependency patches for net/simplex-chat.
#
# The Makefile exports the versioned patch lists and extraction paths so the
# dependency data stays declarative; this script owns the control flow.

set -eu

: "${WRKDIR:?}" "${WRKSRC:?}" "${FILESDIR:?}" "${LOCALBASE:?}"
: "${CHAT_CABAL_PACKAGE_PATHS:?}"

find "$WRKDIR" -type f \
	\( -name '*.hs' -o -name '*.cabal' -o -name '*.sql' \
	   -o -name '*.h' -o -name '*.c' \) \
	-exec "$LOCALBASE/bin/dos2unix" -q {} +

for plan_name in chat_query_plans.txt agent_query_plans.txt; do
	if [ -f "$FILESDIR/$plan_name" ]; then
		# shellcheck disable=SC2086
		$INSTALL_DATA "$FILESDIR/$plan_name" \
			"$WRKSRC/src/Simplex/Chat/Store/SQLite/Migrations/$plan_name"
	fi
done

patch -d "$WRKDIR/direct-sqlcipher" -p0 \
	< "$FILESDIR/direct-sqlcipher/patch-direct-sqlcipher_cabal"

if [ ! -f "$WITHERABLE_DIR/witherable.cabal" ]; then
	"$TAR" -C "$WRKDIR" -xzf "$WITHERABLE_TARBALL"
fi

# shellcheck disable=SC2086
sh "$FILESDIR/check-package-paths.sh" $CHAT_CABAL_PACKAGE_PATHS

for patch_name in $SIMPLEXMQ_PATCHES; do
	patch -d "$WRKDIR/simplexmq" -p0 < "$FILESDIR/simplexmq/$patch_name"
done

for patch_name in $AESON_PATCHES; do
	patch -d "$WRKDIR/aeson" -p0 < "$FILESDIR/aeson/$patch_name"
done

for patch_name in $CRYPTOSTORE_PATCHES; do
	directory="$WRKDIR/cryptostore-$CRYPTOSTORE_V"
	if [ -d "$directory" ]; then
		patch -d "$directory" -p0 < "$FILESDIR/cryptostore/$patch_name"
	fi
done

network_directory="$WRKDIR/network-$NETWORK_V"
if [ -f "$network_directory/network.cabal" ]; then
	patch -d "$network_directory" -p0 \
		< "$FILESDIR/network/patch-network_cabal"
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$network_directory/include"
	# shellcheck disable=SC2086
	$INSTALL_DATA "$FILESDIR/network/HsNetworkConfig.h" \
		"$network_directory/include/HsNetworkConfig.h"
fi

for patch_name in $TLS_PATCHES; do
	directory="$WRKDIR/tls-$TLS_V"
	if [ -d "$directory" ]; then
		patch -d "$directory" -p0 < "$FILESDIR/tls/$patch_name"
	fi
done

for patch_name in $HTTP2_PATCHES; do
	directory="$WRKDIR/http2-$HTTP2_V"
	if [ -d "$directory" ]; then
		patch -d "$directory" -p0 < "$FILESDIR/http2/$patch_name"
	fi
done

unix_time_directory="$WRKDIR/unix-time-$UNIX_TIME_V"
if [ -f "$unix_time_directory/unix-time.cabal" ]; then
	patch -d "$unix_time_directory" -p0 \
		< "$FILESDIR/unix-time/patch-unix-time_cabal"
	# shellcheck disable=SC2086
	$INSTALL_DATA "$FILESDIR/unix-time/UnixTimeConfig.h" \
		"$unix_time_directory/cbits/config.h"
fi

entropy_directory="$WRKDIR/entropy-$ENTROPY_V"
if [ -f "$entropy_directory/entropy.cabal" ]; then
	patch -d "$entropy_directory" -p0 \
		< "$FILESDIR/entropy/patch-entropy_cabal"
fi
