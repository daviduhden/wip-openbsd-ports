#!/bin/sh
# Prefix FVWM3 manuals and commands so they do not collide with FVWM 2.
# Usage: rename-paths.sh PREFIX_ROOT

set -eu

root=${1:?usage: rename-paths.sh PREFIX_ROOT}
manual_directory="$root/man/man1"
binary_directory="$root/bin"

for manual in "$manual_directory"/Fvwm*.1; do
	[ -e "$manual" ] || continue
	mv "$manual" "$manual_directory/fvwm3-${manual##*/}"
done

for manual in \
	fvwm-convert-2.6.1 fvwm-menu-desktop.1 fvwm-menu-directory.1 \
	fvwm-menu-xlock.1 fvwm-perllib.1 fvwm-root.1; do
	mv "$manual_directory/$manual" \
		"$manual_directory/fvwm3-${manual#fvwm-}"
done

mv "$manual_directory/fvwm3-FvwmCommand.1" \
	"$manual_directory/fvwm3-FvwmCommand3.1"

for binary in \
	fvwm-convert-2.6 fvwm-menu-desktop fvwm-menu-directory \
	fvwm-menu-xlock fvwm-perllib fvwm-root; do
	mv "$binary_directory/$binary" \
		"$binary_directory/fvwm3-${binary#fvwm-}"
done

mv "$binary_directory/FvwmCommand" "$binary_directory/FvwmCommand3"
