#!/bin/sh
# Link or install uutils coreutils locale catalogs.
# Usage: locales.sh link|install

set -eu

: "${WRKSRC:?}" "${PREFIX:?}" "${INSTALL_DATA:?}" "${INSTALL_DATA_DIR:?}"

install_data() {
	# shellcheck disable=SC2086
	$INSTALL_DATA "$@"
}
install_data_dir() {
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$@"
}

[ -d "$WRKSRC/src" ] || {
	echo "missing source tree: $WRKSRC/src" >&2
	exit 1
}

mode=${1:?usage: locales.sh link|install}

case "$mode" in
link)
	: "${MODCARGO_TARGET_DIR:?}"
	destination="$MODCARGO_TARGET_DIR/release/locales"
	install_data_dir "$destination"
	ln -fs "$WRKSRC/src/uucore/locales" "$destination/uucore"
	for directory in "$WRKSRC"/src/uu/*/locales; do
		[ -d "$directory" ] || continue
		without_suffix=${directory%/locales}
		ln -fs "$directory" "$destination/${without_suffix##*/}"
	done
	;;
install)
	find "$WRKSRC/src" -path '*/locales/*.ftl' -type f |
		while IFS= read -r catalog; do
			relative=${catalog#"$WRKSRC/"}
			install_data_dir "$PREFIX/share/uutils-coreutils/${relative%/*}"
			install_data "$catalog" \
				"$PREFIX/share/uutils-coreutils/$relative"
		done
	;;
*)
	echo "locales.sh: unknown mode: $mode" >&2
	exit 1
	;;
esac
