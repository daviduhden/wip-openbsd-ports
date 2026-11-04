#!/bin/sh
# Run the maintainer-only cabal-inc stages for net/simplexmq.
# Usage: cabal-inc.sh build|test|merge

set -eu

: "${CABAL_INC_HOME:?}" "${LOCALBASE:?}" "${WRKDIR:?}" "${WRKBUILD:?}"
: "${PORTDIR:?}" "${FILESDIR:?}" "${MODCABAL_STEM:?}" "${MODCABAL_VERSION:?}"
: "${SIMPLEXMQ_CABAL_PACKAGE_PATHS:?}" "${INSTALL_DATA_DIR:?}"
: "${CABAL_INC_SKIP:?}" "${CABAL_INC_EXTRA:?}"

mode=${1:?usage: cabal-inc.sh build|test|merge}

run_cabal() {
	env HOME="$CABAL_INC_HOME" CABAL_DIR="$CABAL_INC_HOME/.cabal" \
		LC_ALL=en_US.UTF-8 "$LOCALBASE/bin/cabal" "$@"
}

run_bundler() {
	env HOME="$CABAL_INC_HOME" CABAL_DIR="$CABAL_INC_HOME/.cabal" \
		LC_ALL=en_US.UTF-8 "$LOCALBASE/bin/cabal-bundler" --openbsd "$@"
}

case "$mode" in
build)
	# shellcheck disable=SC2086
	sh "$FILESDIR/check-package-paths.sh" $SIMPLEXMQ_CABAL_PACKAGE_PATHS
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$CABAL_INC_HOME"
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$CABAL_INC_HOME/.cabal"
	run_cabal update
	if [ ! -f "$CABAL_INC_HOME/.cabal/config" ] &&
		[ -f "$CABAL_INC_HOME/.config/cabal/config" ]; then
		cp "$CABAL_INC_HOME/.config/cabal/config" \
			"$CABAL_INC_HOME/.cabal/config"
	fi
	cd "$WRKBUILD"
	run_cabal v2-build --dry-run \
		-w "$LOCALBASE/bin/ghc" \
		--disable-benchmarks --disable-tests \
		exe:smp-server exe:xftp-server
	run_bundler \
		--plan dist-newstyle/cache/plan.json \
		--executable smp-server \
		"$MODCABAL_STEM-$MODCABAL_VERSION" \
		> "$WRKDIR/simplexmq.smp.inc"
	run_bundler \
		--plan dist-newstyle/cache/plan.json \
		--executable xftp-server \
		"$MODCABAL_STEM-$MODCABAL_VERSION" \
		> "$WRKDIR/simplexmq.xftp.inc"
	;;
test)
	cd "$WRKBUILD"
	run_cabal v2-test --dry-run \
		-w "$LOCALBASE/bin/ghc" \
		--disable-benchmarks \
		test:simplexmq-test
	cp "$WRKBUILD/dist-newstyle/cache/plan.json" \
		"$WRKDIR/simplexmq.test.plan.json"
	;;
merge)
	env SKIP="$CABAL_INC_SKIP" EXTRA="$CABAL_INC_EXTRA" \
		perl "$FILESDIR/cabal-deps-merge.pl" \
		"$WRKDIR/simplexmq.smp.inc" "$WRKDIR/simplexmq.xftp.inc" \
		"$WRKDIR/simplexmq.test.plan.json" \
		> "$WRKDIR/cabal.inc.new"
	mv "$WRKDIR/cabal.inc.new" "$PORTDIR/cabal.inc"
	;;
*)
	echo "cabal-inc.sh: unknown mode: $mode" >&2
	exit 1
	;;
esac
