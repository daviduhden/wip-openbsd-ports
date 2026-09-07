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
		"[INFO] $*" >&2
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
	typeset dir

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

# Select actual category/port paths, never whole categories.
list_directories() {
	typeset ports
	ports=$(list_all_directories) || return 1
	log "Select a port to copy from wip-openbsd-ports:"
	select DIRECTORY in $ports; do
		if [ -n "$DIRECTORY" ]; then
			log "You selected $DIRECTORY"
			DIRECTORY=${DIRECTORY%/} # Remove the trailing slash
			break
		else
			warn "Invalid selection. Please try again."
		fi
	done
}

# Only directories containing a port Makefile are installable.
list_all_directories() {
	typeset makefile found=0
	for makefile in */*/Makefile; do
		[ -f "$makefile" ] || continue
		validate_port_path "${makefile%/Makefile}" || return 1
		print -r -- "${makefile%/Makefile}"
		found=1
	done
	if [ "$found" -eq 0 ]; then
		error "No port directories found in wip-openbsd-ports."
		return 1
	fi
}

# Function to prompt for a space-separated list of port directories.
prompt_selected_directories() {
	log "Enter category/port paths separated by spaces (e.g. net/simplexmq):"
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

# Reject category-only paths, traversal and symlinked port roots.
validate_port_path() {
	typeset port=$1 category name
	case "$port" in
	*/*/* | /* | *[!a-zA-Z0-9_+./-]* | */ | ./* | ../*)
		error "Invalid category/port: $port"
		return 1
		;;
	*/*) ;;
	*)
		error "Expected category/port, not: $port"
		return 1
		;;
	esac
	category=${port%/*}
	name=${port#*/}
	case "$category:$name" in
	.*:* | *:.*)
		error "Invalid category/port: $port"
		return 1
		;;
	esac
	if [ -L "$category" ] || [ -L "$port" ] ||
		[ -L "$port/Makefile" ] || [ ! -f "$port/Makefile" ]; then
		error "Not a local port directory: $port"
		return 1
	fi
}

# Replace only one port. Keep the old directory recoverable and preserve
# nested CVS metadata; never remove a category or unrelated ports.
copy_directory() {
	typeset category name target stage backup="" cvs
	validate_port_path "$DIRECTORY" || return 1
	category=${DIRECTORY%/*}
	name=${DIRECTORY#*/}
	target="$TARGET_TREE/$DIRECTORY"
	if [ ! -d "$TARGET_TREE/infrastructure" ] ||
		[ ! -f "$TARGET_TREE/Makefile" ] ||
		[ ! -d "$TARGET_TREE/$category" ] ||
		[ -L "$TARGET_TREE/$category" ] || [ -L "$target" ] ||
		{ [ -e "$target" ] && [ ! -d "$target" ]; }; then
		error "Invalid ports tree or destination: $target"
		return 1
	fi
	stage=$(mktemp -d "$TARGET_TREE/.wip-port.XXXXXXXX") || return 1
	cp -Rp "$DIRECTORY" "$stage/port" || return 1
	# A private Git checkout may be 0700/0600; _pbuild must read the port.
	find "$stage/port" -type d -exec chmod a+rx,go-w {} + || return 1
	find "$stage/port" -type f -exec chmod a+r,go-w {} + || return 1
	find "$stage/port" -type f -perm -0100 -exec chmod a+x {} + || return 1
	if [ -d "$target" ]; then
		(cd "$target" && find . -type d -name CVS -prune) |
			while IFS= read -r cvs; do
				mkdir -p "$stage/port/${cvs%/*}" || exit 1
				cp -Rp "$target/$cvs" "$stage/port/$cvs" || exit 1
			done || return 1
		if [ -L "$TARGET_TREE/.wip-backups" ]; then
			error "Refusing symlinked backup directory"
			return 1
		fi
		mkdir -p "$TARGET_TREE/.wip-backups" || return 1
		backup=$(mktemp -d "$TARGET_TREE/.wip-backups/$category-$name.XXXXXXXX") ||
			return 1
		mv "$target" "$backup/port" || return 1
		log "Previous $DIRECTORY saved in $backup/port"
	fi
	if ! mv "$stage/port" "$target"; then
		[ -z "${backup:-}" ] || mv "$backup/port" "$target"
		error "Copy failed; staging directory: $stage"
		return 1
	fi
	rmdir "$stage" || return 1
	log "$DIRECTORY copied to $target"
}

copy_all_directories() {
	typeset ports
	ports=$(list_all_directories) || return 1
	for DIRECTORY in $ports; do
		copy_directory || return 1
	done
}

copy_selected_directories() {
	# Validate the whole selection before modifying the destination.
	for DIRECTORY in $SELECTED_DIRECTORIES; do
		validate_port_path "$DIRECTORY" || return 1
	done
	for DIRECTORY in $SELECTED_DIRECTORIES; do
		copy_directory || return 1
	done
}

# Merge only accounts belonging to ports in this repository. Never replace
# the cloned tree's registry with our potentially older upstream snapshot.
copy_user_list() {
	typeset registry="$TARGET_TREE/infrastructure/db/user.list" stage ports
	if [ ! -f user.list ]; then
		warn "user.list not found; package user validation may fail."
		return 1
	fi
	if [ -L "$TARGET_TREE/infrastructure" ] ||
		[ -L "$TARGET_TREE/infrastructure/db" ] ||
		[ -L "$registry" ] || [ ! -f "$registry" ]; then
		error "Missing or symlinked user registry: $registry"
		return 1
	fi
	ports=$(list_all_directories) || return 1
	stage=$(mktemp "$TARGET_TREE/infrastructure/db/.user.list.XXXXXXXX") ||
		return 1
	cp -p "$registry" "$stage" || return 1
	if ! awk -v ports="$ports" '
		BEGIN {
			n = split(ports, paths, "\n")
			for (i = 1; i <= n; i++) present[paths[i]] = 1
		}
		function localport(path, pos, prefix, count, names, j) {
			if (path in present) return 1
			pos = index(path, "{")
			if (!pos || substr(path, length(path)) != "}") return 0
			prefix = substr(path, 1, pos - 1)
			count = split(substr(path, pos + 1, length(path) - pos - 1), names, ",")
			for (j = 1; j <= count; j++)
				if ((prefix names[j]) in present) return 1
			return 0
		}
		NR == FNR {
			if ($1 ~ /^[0-9]+$/ && localport($NF)) {
				ids[++total] = $1
				rows[$1] = $0
				users[$1] = $2
				groups[$1] = $3
			}
			next
		}
		$1 ~ /^[0-9]+$/ {
			for (id in rows) {
				if (($1 == id && ($2 != users[id] || $3 != groups[id])) ||
					($1 != id && ($2 == users[id] || $3 == groups[id]))) {
					print "Account ID/name conflict for local port: " rows[id] > "/dev/stderr"
					bad = 1
				}
			}
			seen[$1] = 1
		}
		{ print }
		END {
			if (bad) exit 1
			for (i = 1; i <= total; i++)
				if (!(ids[i] in seen)) print rows[ids[i]]
		}
	' user.list "$registry" >"$stage"; then
		rm -f "$stage"
		error "User registry unchanged; resolve conflicting port IDs first."
		return 1
	fi
	mv "$stage" "$registry" || return 1
	log "Local port accounts merged into $registry"
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

# Resolve a user-selected checkout without CDPATH output or a symlinked root.
canonical_target_tree() {
	typeset path=$1
	while [ "${path%/}" != "$path" ] && [ "$path" != "/" ]; do
		path=${path%/}
	done
	if [ -L "$path" ]; then
		error "Refusing symlinked checkout root: $path"
		return 1
	fi
	(
		unset CDPATH
		cd -- "$path" && pwd -P
	)
}

# Main function
main() {
	# Copy into an existing CVS/Git tree without host provisioning or checkout.
	case "${1:-}" in
	--list)
		move_to_wip_openbsd_ports
		list_all_directories
		return $?
		;;
	--copy-only)
		[ "$#" -ge 2 ] || {
			error "Usage: $0 --copy-only TREE [category/port ...]"
			return 1
		}
		TARGET_TREE=$(canonical_target_tree "$2") || return 1
		shift 2
		move_to_wip_openbsd_ports
		if [ "$#" -eq 0 ]; then
			copy_all_directories || return 1
		else
			# Port paths cannot contain whitespace.
			for DIRECTORY in "$@"; do
				validate_port_path "$DIRECTORY" || return 1
			done
			SELECTED_DIRECTORIES="$*"
			copy_selected_directories || return 1
		fi
		copy_user_list
		return $?
		;;
	"") ;;
	*)
		error "Usage: $0 [--list | --copy-only TREE [category/port ...]]"
		return 1
		;;
	esac
	check_root
	set_cvsroot
	checkout_ports_tree
	ask_copy_from_wip
	if [ "${DO_COPY:-0}" -eq 1 ]; then
		move_to_wip_openbsd_ports
		choose_target_tree
		TARGET_TREE=$(canonical_target_tree "$TARGET_TREE") || return 1
		if [ "${COPY_ALL:-0}" -eq 1 ]; then
			copy_all_directories || return 1
		elif [ "${COPY_LIST:-0}" -eq 1 ]; then
			prompt_selected_directories
			copy_selected_directories || return 1
		else
			list_directories
			copy_directory || return 1
		fi
		copy_user_list || return 1
	else
		log "Skipping copy from wip-openbsd-ports."
	fi
	create_user_with_random_password
	configure_doas
	configure_ports_system
}

# Execute the main function
main "$@"
