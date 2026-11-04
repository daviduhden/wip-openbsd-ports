#!/bin/sh
# Regenerate cabal.inc with cabal-bundler and keep MODCABAL_STEM/VERSION in
# the port Makefile.  The replace is atomic after a successful bundler run.

set -eu

: "${CABAL_INC_HOME:?}" "${LOCALBASE:?}" "${WRKDIR:?}" "${PORTDIR:?}"
: "${MODCABAL_STEM:?}" "${MODCABAL_VERSION:?}" "${INSTALL_DATA_DIR:?}"

# shellcheck disable=SC2086
$INSTALL_DATA_DIR "$CABAL_INC_HOME"
# shellcheck disable=SC2086
$INSTALL_DATA_DIR "$CABAL_INC_HOME/.cabal"

env HOME="$CABAL_INC_HOME" CABAL_DIR="$CABAL_INC_HOME/.cabal" \
	LC_ALL=en_US.UTF-8 \
	"$LOCALBASE/bin/cabal" update

if [ ! -f "$CABAL_INC_HOME/.cabal/config" ] &&
	[ -f "$CABAL_INC_HOME/.config/cabal/config" ]; then
	cp "$CABAL_INC_HOME/.config/cabal/config" \
		"$CABAL_INC_HOME/.cabal/config"
fi

env HOME="$CABAL_INC_HOME" CABAL_DIR="$CABAL_INC_HOME/.cabal" \
	LC_ALL=en_US.UTF-8 \
	"$LOCALBASE/bin/cabal-bundler" --openbsd \
	"$MODCABAL_STEM-$MODCABAL_VERSION" \
	> "$WRKDIR/cabal.inc.raw"

sed -e '/^MODCABAL_STEM[[:space:]]*=/d' \
	-e '/^MODCABAL_VERSION[[:space:]]*=/d' \
	"$WRKDIR/cabal.inc.raw" > "$WRKDIR/cabal.inc.new"
mv "$WRKDIR/cabal.inc.new" "$PORTDIR/cabal.inc"
