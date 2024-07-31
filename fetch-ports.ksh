#!/bin/ksh

# Copyright (c) 2024 David Uhden Collado <david@uhden.dev>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Directories for ports configuration
WRKOBJDIR="/usr/obj/ports"
DISTDIR="/usr/distfiles"
PACKAGE_REPOSITORY="/usr/packages"

# Check if the ports directory exists
if [ -d /usr/ports ]; then
	echo "/usr/ports directory exists. Updating the repository with CVS."
	cd /usr/ports || exit 1
	cvs -q up -Pd -A
else
	# Checkout the ports tree using CVS
	cd /usr || exit 1
	cvs -qd anoncvs@anoncvs.eu.openbsd.org:/cvs checkout -P ports
fi

# Move to the wip-openbsd-ports directory
wip_openbsd_ports_dir=$(find / -type d -name "wip-openbsd-ports" 2>/dev/null | head -n 1)
if [ -z "$wip_openbsd_ports_dir" ]; then
	echo "wip-openbsd-ports directory not found."
	exit 1
fi
cd "$wip_openbsd_ports_dir" || exit 1

# List directories in the current directory
list_directories() {
	echo "Select a directory to copy:"
	select DIRECTORY in */; do
		if [ -n "$DIRECTORY" ]; then
			echo "You selected $DIRECTORY"
			DIRECTORY=${DIRECTORY%/}  # Remove trailing slash
			break
		else
			echo "Invalid selection. Please try again."
		fi
	done
}

# List subdirectories in /usr/ports
list_ports_subdirectories() {
	echo "Select a subdirectory in /usr/ports where the directory will be copied:"
	select SUBDIRECTORY in /usr/ports/*/; do
		if [ -n "$SUBDIRECTORY" ]; then
			echo "You selected $SUBDIRECTORY"
			SUBDIRECTORY=${SUBDIRECTORY%/}  # Remove trailing slash
			break
		else
			echo "Invalid selection. Please try again."
		fi
	done
}

# Copy the selected directory to the chosen subdirectory in /usr/ports
copy_directory() {
	TARGET_DIR="$SUBDIRECTORY/$DIRECTORY"
	if [ -d "$TARGET_DIR" ]; then
		echo "Directory $TARGET_DIR already exists. Removing files except 'CVS' directory."
		find "$TARGET_DIR" -mindepth 1 ! -name "CVS" -exec rm -rf {} +
	fi
	cp -R "$DIRECTORY" "$SUBDIRECTORY/"
	echo "Directory $DIRECTORY copied to $SUBDIRECTORY/"
}

# Main function
main() {
	list_directories
	list_ports_subdirectories
	copy_directory
}

# Run the main function
main

# Remove the mk.conf file
rm -f /etc/mk.conf

# Configure the ports system in /etc/mk.conf
echo "Configuring the ports system in /etc/mk.conf..."
{
	echo "WRKOBJDIR=$WRKOBJDIR"
	echo "DISTDIR=$DISTDIR"
	echo "PACKAGE_REPOSITORY=$PACKAGE_REPOSITORY"
} >> /etc/mk.conf

echo "Configuration complete. The ports tree has been installed and configured successfully."
