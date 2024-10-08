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

# Remove the ports directory
rm -rf /usr/ports

# Set CVSROOT environment variable permanently if not already set
if ! grep -q "export CVSROOT=anoncvs@anoncvs.eu.openbsd.org:/cvs" ~/.profile; then
	echo "export CVSROOT=anoncvs@anoncvs.eu.openbsd.org:/cvs" >> ~/.profile
	echo "CVSROOT variable added to ~/.profile"
else
	echo "CVSROOT variable already exists in ~/.profile"
fi
export CVSROOT="anoncvs@anoncvs.eu.openbsd.org:/cvs"

# Directories for building ports
WRKOBJDIR="/usr/obj/ports"
DISTDIR="/usr/distfiles"
PACKAGE_REPOSITORY="/usr/packages"

# Checkout the ports tree using CVS
cd /usr || exit 1
cvs -qd anoncvs@anoncvs.eu.openbsd.org:/cvs checkout -P ports

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
		echo "Directory $TARGET_DIR already exists. Removing files except 'CVS' directories."
		find "$TARGET_DIR" -mindepth 1 ! -name "CVS" -exec rm -rf {} +
	fi
	cp -R "$DIRECTORY" "$SUBDIRECTORY/"
	echo "Directory $DIRECTORY copied to $SUBDIRECTORY/"
}

# Create a user 'user' with a random password
create_user_with_random_password() {
	# Generate a random password
	PASSWORD=$(openssl rand -base64 12)
	
	# Create the user with a home directory and set the password
	useradd -m -s /bin/ksh user
	
	# Encrypt the password and set it using usermod
	ENCRYPTED_PASSWORD=$(encrypt -b 6 "$PASSWORD")
	usermod -p "$ENCRYPTED_PASSWORD" user
	
	echo "User 'user' created with password: $PASSWORD"
}

# Configure doas
configure_doas() {
	# Copy the example doas.conf to /etc/
	cp /etc/examples/doas.conf /etc/doas.conf
	
	# Add the required line to /etc/doas.conf
	echo "permit keepenv persist user" >> /etc/doas.conf
	
	echo "doas configured successfully. /etc/doas.conf updated."
}

# Main function
main() {
	list_directories
	list_ports_subdirectories
	copy_directory
	create_user_with_random_password
	configure_doas
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
	echo "SUDO=doas"
} >> /etc/mk.conf

echo "Configuration complete. The ports tree has been installed and configured successfully."
