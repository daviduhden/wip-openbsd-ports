#!/bin/ksh

# Copyright (c) 2024-2026 David David Uhden Collado <david@uhden.dev>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
# OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

log() {
	print "$(date '+%Y-%m-%d %H:%M:%S')" \
		"[INFO] $*"
}
warn() {
	print "$(date '+%Y-%m-%d %H:%M:%S')" \
		"[WARN] $*" >&2
}
error() {
	print "$(date '+%Y-%m-%d %H:%M:%S')" \
		"[ERROR] $*" >&2
}

# Verify that the script is run as root
check_root() {
	if [ "$(id -u)" -ne 0 ]; then
		error "This script must be run as root."
		exit 1
	fi
}

# Set CVSROOT in .profile if not already configured
set_cvsroot() {
	if [ ! -f "$HOME/.profile" ] ||
		! grep -Fq "export CVSROOT=anoncvs@anoncvs.eu.openbsd.org:/cvs" \
			"$HOME/.profile"; then
		print "export CVSROOT=anoncvs@anoncvs.eu.openbsd.org:/cvs" \
			>>"$HOME/.profile"
		log "CVSROOT variable added to ~/.profile"
	else
		log "CVSROOT variable already exists in ~/.profile"
	fi
	export CVSROOT="anoncvs@anoncvs.eu.openbsd.org:/cvs"
}

# Function to remove the ports content
remove_ports_content() {
	find /usr/ports -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
}

# Function to checkout the ports tree using CVS (removes old tree first)
checkout_ports_tree() {
	cd /usr || exit 1
	remove_ports_content
	log "Checking out ports tree from anoncvs..."
	cvs -qd anoncvs@anoncvs.eu.openbsd.org:/cvs checkout -P ports
	pkg_add pkglocatedb
}

# Ask if user wants to copy from wip-openbsd-ports (optional)
ask_copy_from_wip() {
	log "Copy ports from 'wip-openbsd-ports' into /usr/ports?"
	select ANSWER in "One port" "Selected ports" "All ports" "No"; do
		case "$ANSWER" in
		"One port")
			DO_COPY=1
			COPY_ALL=0
			COPY_LIST=0
			break
			;;
		"Selected ports")
			DO_COPY=1
			COPY_ALL=0
			COPY_LIST=1
			break
			;;
		"All ports")
			DO_COPY=1
			COPY_ALL=1
			COPY_LIST=0
			break
			;;
		No)
			DO_COPY=0
			break
			;;
		*) warn "Invalid selection. Please try again." ;;
		esac
	done
}

# Resolve local wip-openbsd-ports path. Checks, in order:
#   1. WIP_OPENBSD_PORTS_DIR environment variable
#   2. Script's own directory (if named wip-openbsd-ports)
#   3. Common locations under $HOME and /usr
#   4. Current working directory or its parent
#   5. Limited filesystem search
resolve_local_port_dir() {
	local dir

	# 1. Explicit environment variable
	if [ -n "${WIP_OPENBSD_PORTS_DIR:-}" ] &&
		[ -d "$WIP_OPENBSD_PORTS_DIR/.git" ]; then
		log "Using WIP_OPENBSD_PORTS_DIR=$WIP_OPENBSD_PORTS_DIR"
		print "$WIP_OPENBSD_PORTS_DIR"
		return 0
	fi

	# 2. Script directory (if the script lives inside the repo)
	dir=$(
		unset CDPATH
		cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P
	)
	while [ -n "$dir" ] && [ "$dir" != "/" ]; do
		if [ "$(basename "$dir")" = "wip-openbsd-ports" ] &&
			[ -d "$dir/.git" ]; then
			log "Found wip-openbsd-ports at $dir"
			print "$dir"
			return 0
		fi
		dir=$(dirname "$dir")
	done

	# 3. Common locations: $HOME, home directories, /usr
	for dir in \
		"${HOME:-}/wip-openbsd-ports" \
		/root/wip-openbsd-ports \
		/usr/wip-openbsd-ports \
		"${HOME:-}/git/wip-openbsd-ports"; do
		if [ -d "$dir/.git" ]; then
			log "Found wip-openbsd-ports at $dir"
			print "$dir"
			return 0
		fi
	done

	# 4. Scan home directories for wip-openbsd-ports
	for dir in /home/*/wip-openbsd-ports /home/*/git/wip-openbsd-ports; do
		if [ -d "$dir/.git" ]; then
			log "Found wip-openbsd-ports at $dir"
			print "$dir"
			return 0
		fi
	done

	# 5. Current directory or parent
	if [ -d "$PWD/.git" ] &&
		[ "$(basename "$PWD")" = "wip-openbsd-ports" ]; then
		print "$PWD"
		return 0
	fi
	if [ -d "$PWD/wip-openbsd-ports/.git" ]; then
		print "$PWD/wip-openbsd-ports"
		return 0
	fi

	# 6. Limited search under /home and /usr (skip / to avoid
	#    traversing the entire filesystem).
	warn "Searching /home and /usr for wip-openbsd-ports..."
	dir=$(find /home /usr /root -maxdepth 5 \
		-type d -name "wip-openbsd-ports" \
		-exec test -d '{}/.git' ';' \
		-print -quit 2>/dev/null)
	if [ -n "$dir" ]; then
		log "Found wip-openbsd-ports at $dir"
		print "$dir"
		return 0
	fi

	error "wip-openbsd-ports directory not found." \
		"Set WIP_OPENBSD_PORTS_DIR to its location."
	exit 1
}

# Change to the wip-openbsd-ports directory.
move_to_wip_openbsd_ports() {
	wip_openbsd_ports_dir=$(resolve_local_port_dir)
	cd "$wip_openbsd_ports_dir" || {
		error "Could not cd to $wip_openbsd_ports_dir"
		exit 1
	}
}

# Function to list directories in wip-openbsd-ports and select one
list_directories() {
	log "Select a directory to copy from wip-openbsd-ports:"
	select DIRECTORY in */; do
		if [ -n "$DIRECTORY" ]; then
			log "You selected $DIRECTORY"
			DIRECTORY=${DIRECTORY%/} # Remove the trailing slash
			break
		else
			warn "Invalid selection. Please try again."
		fi
	done
}

# Function to list all top-level port directories in wip-openbsd-ports.
list_all_directories() {
	set -- */
	if [ "$1" = "*/" ] || [ ! -d "$1" ]; then
		error "No port directories found in wip-openbsd-ports."
		exit 1
	fi
	print "$*"
}

# Function to prompt for a space-separated list of port directories.
prompt_selected_directories() {
	log "Enter one or more port directories separated by spaces:"
	print -n "> "
	read -r SELECTED_DIRECTORIES
	[ -n "${SELECTED_DIRECTORIES:-}" ] || {
		error "No directories entered."
		exit 1
	}
}

# Choose the target port tree (here always /usr/ports)
choose_target_tree() {
	options=""
	[ -d /usr/ports ] && options="$options /usr/ports"
	if [ -z "$options" ]; then
		error "No destination trees available under /usr."
		exit 1
	fi
	log "Select the target tree for the copy:"
	select TARGET_TREE in $options; do
		if [ -n "$TARGET_TREE" ]; then
			log "You selected $TARGET_TREE"
			break
		else
			warn "Invalid selection. Please try again."
		fi
	done
}

# List category subdirectories and prompt for selection
list_tree_subdirectories() {
	log "Select a subdirectory in $TARGET_TREE" \
		"where the directory will be copied:"
	select SUBDIRECTORY in "$TARGET_TREE"/*/; do
		if [ -n "$SUBDIRECTORY" ]; then
			log "You selected $SUBDIRECTORY"
			SUBDIRECTORY=${SUBDIRECTORY%/} # Remove the trailing slash
			break
		else
			warn "Invalid selection. Please try again."
		fi
	done
}

# Copy the selected directory to the chosen target subdirectory
copy_directory() {
	TARGET_DIR="$SUBDIRECTORY/$DIRECTORY"
	if [ -d "$TARGET_DIR" ]; then
		warn "Directory $TARGET_DIR already exists." \
			"Removing files except 'CVS' directories."
		find "$TARGET_DIR" -mindepth 1 ! -name "CVS" -exec rm -rf {} +
	fi
	cp -R "$DIRECTORY" "$SUBDIRECTORY/"
	log "Directory $DIRECTORY copied to $SUBDIRECTORY/"
}

# Function to copy every top-level port directory into the target tree.
copy_all_directories() {
	ports=$(list_all_directories)
	for DIRECTORY in $ports; do
		TARGET_DIR="$TARGET_TREE/$DIRECTORY"
		if [ -d "$TARGET_DIR" ]; then
			warn "Directory $TARGET_DIR already exists." \
				"Removing files except 'CVS'."
			find "$TARGET_DIR" -mindepth 1 ! -name "CVS" \
				-exec rm -rf {} +
		fi
		cp -R "$DIRECTORY" "$TARGET_TREE/"
		log "Directory $DIRECTORY copied to $TARGET_TREE/"
	done
}

# Copy only the directories explicitly selected by the user.
copy_selected_directories() {
	for DIRECTORY in $SELECTED_DIRECTORIES; do
		if [ ! -d "$DIRECTORY" ]; then
			warn "Skipping unknown directory: $DIRECTORY"
			continue
		fi
		TARGET_DIR="$TARGET_TREE/$DIRECTORY"
		if [ -d "$TARGET_DIR" ]; then
			warn "Directory $TARGET_DIR already exists." \
				"Removing files except 'CVS'."
			find "$TARGET_DIR" -mindepth 1 ! -name "CVS" \
				-exec rm -rf {} +
		fi
		cp -R "$DIRECTORY" "$TARGET_TREE/"
		log "Directory $DIRECTORY copied to $TARGET_TREE/"
	done
}

# Install the user/group registry carried with the custom ports.  Its base is
# kept in sync with upstream and the final entries reserve IDs for these ports.
copy_user_list() {
	if [ ! -f user.list ]; then
		warn "user.list not found; package user validation may fail."
		return
	fi
	cp user.list "$TARGET_TREE/infrastructure/db/user.list"
	log "user.list copied to $TARGET_TREE/infrastructure/db/user.list"
}

# Function to create the user 'user' with a random password
create_user_with_random_password() {
	USER_TO_CREATE="user"

	# Generate a random password
	PASSWORD=$(openssl rand -base64 12)

	# Create the user with a home directory and set the shell to /bin/ksh
	useradd -m -s /bin/ksh "$USER_TO_CREATE"

	# Encrypt the password and set it using usermod
	ENCRYPTED_PASSWORD=$(openssl passwd -1 "$PASSWORD")
	usermod -p "$ENCRYPTED_PASSWORD" "$USER_TO_CREATE"

	log "User 'user' created with password: $PASSWORD"
}

# Function to configure doas
configure_doas() {
	cp /etc/examples/doas.conf /etc/doas.conf
	print "permit keepenv persist user" >>/etc/doas.conf
	log "doas configured successfully. /etc/doas.conf updated."
}

# Ports build configuration
WRKOBJDIR="/usr/obj/ports"
DISTDIR="/usr/distfiles"
PACKAGE_REPOSITORY="/usr/packages"

# Function to configure the ports system in /etc/mk.conf
configure_ports_system() {
	rm -f /etc/mk.conf
	log "Configuring the ports system in /etc/mk.conf..."
	{
		print "WRKOBJDIR=$WRKOBJDIR"
		print "DISTDIR=$DISTDIR"
		print "PACKAGE_REPOSITORY=$PACKAGE_REPOSITORY"
		print "SUDO=doas"
	} >>/etc/mk.conf
	log "Configuration complete." \
		"The ports tree has been installed and configured."
}

# Main function
main() {
	check_root
	set_cvsroot
	checkout_ports_tree
	ask_copy_from_wip
	if [ "${DO_COPY:-0}" -eq 1 ]; then
		move_to_wip_openbsd_ports
		choose_target_tree
		if [ "${COPY_ALL:-0}" -eq 1 ]; then
			copy_all_directories
		elif [ "${COPY_LIST:-0}" -eq 1 ]; then
			prompt_selected_directories
			copy_selected_directories
		else
			list_directories
			list_tree_subdirectories
			copy_directory
		fi
		copy_user_list
	else
		log "Skipping copy from wip-openbsd-ports."
	fi
	create_user_with_random_password
	configure_doas
	configure_ports_system
}

# Execute the main function
main
