#!/bin/sh
# Install XFile data files, add-on type maps, icons and examples.
# Binary and manual-page installation stays in the port Makefile.

set -eu

: "${WRKSRC:?}" "${PREFIX:?}" "${TRUEPREFIX:?}" "${INSTALL_DATA:?}"
: "${INSTALL_DATA_DIR:?}"

install_data() {
	# shellcheck disable=SC2086
	$INSTALL_DATA "$@"
}
install_data_dir() {
	# shellcheck disable=SC2086
	$INSTALL_DATA_DIR "$@"
}

install_data_dir "$PREFIX/share/xfile/types"
install_data "$WRKSRC/src/default.db" "$PREFIX/share/xfile/types/system.db"

install_data_dir "$PREFIX/share/xfile/icons"
for icon in "$WRKSRC"/src/icons/*.xpm; do
	[ -f "$icon" ] || continue
	install_data "$icon" "$PREFIX/share/xfile/icons/"
done
install_data "$WRKSRC/src/icons/README" "$PREFIX/share/xfile/README.icons"

install_data_dir "$PREFIX/share/pixmaps"
install_data "$WRKSRC/src/xbm/cabinet.xpm" \
	"$PREFIX/share/pixmaps/xfile_48x48.xpm"
install_data "$WRKSRC/src/xbm/cabinet64.xpm" \
	"$PREFIX/share/pixmaps/xfile_64x64.xpm"

# xfile-addon: additional type definitions and icons.  XFile loads every
# *.db from share/xfile/types and looks icons up in share/xfile/icons, so
# these are used automatically; user files in ~/.xfile/{types,icons} still
# take precedence.
for type_file in "$WRKSRC"/xfile-addon/types/*.db; do
	[ -f "$type_file" ] || continue
	install_data "$type_file" "$PREFIX/share/xfile/types/"
done
for icon in "$WRKSRC"/xfile-addon/icons/*.xpm; do
	[ -f "$icon" ] || continue
	case "$icon" in
	*file.[lmst].xpm) continue ;;
	esac
	install_data "$icon" "$PREFIX/share/xfile/icons/"
done
install_data "$WRKSRC/xfile-addon/README" "$PREFIX/share/xfile/README.addon"

# Alternative "file" icons are shipped as examples only, so they do not
# override the default icon set.
install_data_dir "$PREFIX/share/examples/xfile/addon/icons"
install_data \
	"$WRKSRC/xfile-addon/icons/file.l.xpm" \
	"$WRKSRC/xfile-addon/icons/file.m.xpm" \
	"$WRKSRC/xfile-addon/icons/file.s.xpm" \
	"$WRKSRC/xfile-addon/icons/file.t.xpm" \
	"$PREFIX/share/examples/xfile/addon/icons/"

# xfind
install_data "$WRKSRC/xfind/xfind.xpm" "$PREFIX/share/pixmaps/xfind_48x48.xpm"

# xfile-xdgsvc (XDG/freedesktop D-Bus file manager shim)
install_data_dir "$PREFIX/share/dbus-1/services"
sed "s|^Exec=.*\$|Exec=$TRUEPREFIX/bin/xfile-xdgsvc|" \
	"$WRKSRC/xfile-xdgsvc/xfile.service" > "$WRKSRC/xfile.service"
install_data "$WRKSRC/xfile.service" \
	"$PREFIX/share/dbus-1/services/xfile.service"

# Optional slanted icons (not selected by default).
install_data_dir "$PREFIX/share/examples/xfile/slanted-icons"
for icon in "$WRKSRC"/slanted-icons/*.xpm; do
	[ -f "$icon" ] || continue
	install_data "$icon" "$PREFIX/share/examples/xfile/slanted-icons/"
done
