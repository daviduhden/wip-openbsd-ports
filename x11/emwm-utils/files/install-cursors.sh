#!/bin/sh
# Install the core-hr cursor theme, preserving symbolic links in the theme.

set -eu

: "${WRKDIR:?}" "${PREFIX:?}" "${INSTALL_DATA:?}" "${INSTALL_DATA_DIR:?}"

install_data() {
	# shellcheck disable=SC2086
	$INSTALL_DATA "$@"
}
install_data_dir() {
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$@"
}

source_directory="$WRKDIR/xc-core-hr/core-hr/cursors"
destination="$PREFIX/share/icons/core-hr/cursors"

[ -d "$source_directory" ] || {
	echo "missing cursor directory: $source_directory" >&2
	exit 1
}

install_data_dir "$destination"
for cursor in "$source_directory"/*; do
	[ -e "$cursor" ] || [ -L "$cursor" ] || continue
	if [ -L "$cursor" ]; then
		ln -s "$(readlink "$cursor")" "$destination/${cursor##*/}"
	else
		install_data "$cursor" "$destination/"
	fi
done
