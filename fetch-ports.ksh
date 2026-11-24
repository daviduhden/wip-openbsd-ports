#!/bin/ksh

# Copyright (c) 2024-2026 David Uhden Collado <david@uhden.dev>
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

set -o pipefail

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

# Use exactly the requested overlay or the checkout containing this script.
move_to_wip_openbsd_ports() {
	unset CDPATH
	typeset source=${WIP_OPENBSD_PORTS_DIR:-$(dirname -- "$0")}
	cd -- "$source" || return 1
	if [ -z "${WIP_OPENBSD_PORTS_DIR:-}" ] && [ ! -f fetch-ports.ksh ]; then
		error "Not an overlay source: $source"
		return 1
	fi
}

# A failed checkout leaves its staging directory for inspection.
bootstrap_tree() {
	typeset requested=$1 parent name stage
	parent=$(canonical_target_tree "$(dirname -- "$requested")") || return 1
	name=$(basename -- "$requested")
	case "$name" in . | .. | / | "") return 1 ;; esac
	[ ! -e "$parent/$name" ] && [ ! -L "$parent/$name" ] || {
		error "Bootstrap requires an unused destination: $parent/$name"
		return 1
	}
	stage=$(mktemp -d "$parent/.ports-bootstrap.XXXXXXXX") || return 1
	if ! (cd "$stage" &&
		cvs -qd "${CVSROOT:-anoncvs@anoncvs.eu.openbsd.org:/cvs}" checkout -P ports) ||
		[ ! -f "$stage/ports/Makefile" ] ||
		[ ! -d "$stage/ports/infrastructure" ]; then
		error "Checkout failed in $stage"
		return 1
	fi
	# Serialize cooperating bootstraps and recheck the name before publish.
	(
		mkdir "$parent/.ports-bootstrap.lock" || exit 1
		trap 'rmdir "$parent/.ports-bootstrap.lock"' EXIT
		[ ! -e "$parent/$name" ] && [ ! -L "$parent/$name" ] || exit 1
		mv "$stage/ports" "$parent/$name" || exit 1
		rmdir "$stage" || exit 1
		log "Checkout available at $parent/$name"
	) || {
		error "Cannot publish checkout; inspect $stage"
		return 1
	}
}

# Only directories containing a port Makefile are installable.  A group
# directory whose Makefile only recurses into subdirectories
# (bsd.port.subdir.mk) is not itself a port; its nested subports are
# listed individually instead.
is_repository_support_path() {
	case "$1" in
	audit/* | logs/* | tools/* | scripts/* | tests/* | docs/* | infrastructure/* | \
		*/CVS/* | */files/* | */patches/* | */pkg/*)
		return 0
		;;
	esac
	return 1
}

list_all_directories() {
	typeset makefile port found=0
	for makefile in */*/Makefile */*/*/Makefile; do
		[ -f "$makefile" ] || continue
		is_repository_support_path "$makefile" && continue
		if grep -q 'bsd\.port\.subdir\.mk' "$makefile"; then
			continue
		fi
		port=${makefile%/Makefile}
		validate_port_path "$port" || return 1
		print -r -- "$port"
		found=1
	done
	if [ "$found" -eq 0 ]; then
		error "No port directories found in wip-openbsd-ports."
		return 1
	fi
}

# Reject category-only paths, traversal and symlinked port roots.  A port
# path is category/port, or category/group/port for a subport nested under
# a group directory (like sysutils/uutils/awk or lang/python/3).
validate_port_path() {
	typeset port=$1 prefix="" rest component depth=0

	if is_repository_support_path "$port/Makefile"; then
		error "Repository support directory is not a port: $port"
		return 1
	fi

	case "$port" in
	/* | */ | ./* | ../* | *[!a-zA-Z0-9_+./-]* | *//*)
		error "Invalid category/port: $port"
		return 1
		;;
	*/*) ;;
	*)
		error "Expected category/port, not: $port"
		return 1
		;;
	esac

	rest=$port
	while [ -n "$rest" ]; do
		component=${rest%%/*}
		case "$component" in
		"" | .*)
			error "Invalid category/port: $port"
			return 1
			;;
		esac
		if [ -z "$prefix" ]; then
			prefix=$component
		else
			prefix=$prefix/$component
		fi
		if [ -L "$prefix" ]; then
			error "Not a local port directory: $port"
			return 1
		fi
		((depth += 1))
		[ "$rest" = "$component" ] && break
		rest=${rest#*/}
	done

	if [ "$depth" -lt 2 ] || [ "$depth" -gt 3 ]; then
		error "Invalid category/port: $port"
		return 1
	fi
	if [ -L "$port/Makefile" ] || [ ! -f "$port/Makefile" ] ||
		[ ! -r "$port/Makefile" ] ||
		grep -q 'bsd\.port\.subdir\.mk' "$port/Makefile"; then
		error "Not a local port directory: $port"
		return 1
	fi
}

# Flatten a category/path into a single filename component.  Only pdksh
# constructs are used: ${var//pat/rep} is ksh93-only and the ksh shipped with
# the OpenBSD base system (pdksh) rejects it with "bad substitution".
flatten_path() {
	print -r -- "$1" | tr '/' '_'
}

# Emit the tracked files under a port, relative to its root and sorted,
# excluding the CVS metadata directories.  Used to build the created/deleted
# lists that drive 'cvs add' and 'cvs remove'.
list_component_files() {
	(
		cd "$1" || exit 1
		find . -type d -name CVS -prune -o -type f -print
	) | sed -e 's|^\./||' -e '/^$/d' | LC_ALL=C sort
}

# Like list_component_files(), but directories only.  CVS has to register a
# new directory before the files it contains, so the created-directory list is
# kept apart from the created-file list.
list_component_dirs() {
	(
		cd "$1" || exit 1
		find . -type d -name CVS -prune -o -type d -print
	) | sed -e 's|^\./||' -e '/^$/d' | LC_ALL=C sort
}

# Record the files that disappeared from and appeared in a replaced port.
# The two plain-text lists live in $TARGET_TREE/.wip-changes/ and contain one
# path per line, relative to the port root: the created list feeds 'cvs add',
# the deleted list feeds 'cvs remove'.  This is what makes it possible to
# build a correct 'cvs diff' after a wholesale directory replacement, since
# the new files come from a Git checkout and have no CVS metadata of their
# own.
write_change_lists() {
	typeset old=$1 new=$2 label=$3
	typeset dir="$transaction/new/.wip-changes"
	typeset tmp

	if [ -L "$dir" ]; then
		warn "Refusing symlinked changes directory: $dir"
		return 1
	fi
	mkdir -p "$dir" || return 1
	tmp=$(mktemp -d "$dir/.$label.XXXXXXXX") || return 1
	if ! list_component_files "$old" >"$tmp/oldfiles" ||
		! list_component_files "$new" >"$tmp/newfiles" ||
		! list_component_dirs "$old" >"$tmp/olddirs" ||
		! list_component_dirs "$new" >"$tmp/newdirs" ||
		! LC_ALL=C comm -13 "$tmp/oldfiles" "$tmp/newfiles" \
			>"$dir/$label.created.txt" ||
		! LC_ALL=C comm -23 "$tmp/oldfiles" "$tmp/newfiles" \
			>"$dir/$label.deleted.txt" ||
		! LC_ALL=C comm -13 "$tmp/olddirs" "$tmp/newdirs" \
			>"$dir/$label.created-dirs.txt"; then
		rm -rf "$tmp"
		return 1
	fi
	rm -rf "$tmp"
	log "Prepared change lists for $label"
}

# Add ancestors to the directory plan without creating them in the target.
plan_directory() {
	typeset path=$1
	if [ -L "$TARGET_TREE/$path" ] ||
		{ [ -e "$TARGET_TREE/$path" ] && [ ! -d "$TARGET_TREE/$path" ]; }; then
		error "Invalid destination directory: $path"
		return 1
	fi
	if [ ! -d "$TARGET_TREE/$path" ]; then
		print -r -- "$path" >>"$transaction/directories" || return 1
	fi
	mkdir -p "$transaction/new/$path"
}

stage_port() {
	typeset port=$1 category=${1%/*} top=${1%%/*} label file path cvs parent
	typeset target="$TARGET_TREE/$1" staged="$transaction/new/$1"
	label=$(flatten_path "$category")-${port##*/}
	[ -d "$TARGET_TREE/$top" ] || return 1
	plan_directory "$top" || return 1
	plan_directory "$category" || return 1
	if [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; then
		error "Invalid destination port: $target"
		return 1
	fi
	if [ "$category" != "$top" ]; then
		for file in "$category"/*; do
			[ -f "$file" ] || continue
			case "${file##*/}" in *[!a-zA-Z0-9_.+-]*) return 1 ;; esac
			[ ! -L "$file" ] && [ ! -L "$TARGET_TREE/$file" ] || return 1
			[ ! -e "$TARGET_TREE/$file" ] || [ -f "$TARGET_TREE/$file" ] ||
				return 1
			cp -p "$file" "$transaction/new/$file" || return 1
			chmod a+r,go-w "$transaction/new/$file" || return 1
			print -r -- "$file" >>"$transaction/plan" || return 1
		done
	fi
	cp -Rp "$port" "$staged" || return 1
	rm -rf "$staged/audit" "$staged/logs" || return 1
	find "$staged" -name CVS -prune -print >"$transaction/source-cvs" ||
		return 1
	if [ -s "$transaction/source-cvs" ]; then
		error "Source port contains CVS metadata: $port"
		return 1
	fi
	find "$staged" -type d -exec chmod a+rx,go-w {} + || return 1
	find "$staged" -type f -exec chmod a+r,go-w {} + || return 1
	find "$staged" -type f -perm -0100 -exec chmod a+x {} + || return 1
	if [ -d "$target" ]; then
		(cd "$target" && find . -type d -name CVS -prune -print) >"$transaction/target-cvs" || return 1
		while IFS= read -r cvs; do
			parent=${cvs%/*}
			while [ "$parent" != "." ]; do
				[ ! -L "$staged/$parent" ] || return 1
				parent=${parent%/*}
			done
			mkdir -p "$staged/${cvs%/*}" || return 1
			cp -Rp "$target/$cvs" "$staged/$cvs" || return 1
		done <"$transaction/target-cvs"
		write_change_lists "$target" "$staged" "$label" || return 1
		for file in created deleted created-dirs; do
			path=".wip-changes/$label.$file.txt"
			[ ! -L "$TARGET_TREE/$path" ] || return 1
			[ ! -e "$TARGET_TREE/$path" ] || [ -f "$TARGET_TREE/$path" ] ||
				return 1
			print -r -- "$path" >>"$transaction/plan" || return 1
		done
	fi
	print -r -- "$port" >>"$transaction/plan"
}

# Reverse only entries whose publication was started. The old and new slots
# distinguish an interrupted rename from an entry that was never replaced.
rollback_overlay() {
	typeset path target old new failed=0
	awk '{paths[NR]=$0} END {for (i=NR; i>0; i--) print paths[i]}' "$transaction/started" >"$transaction/reverse" || return 1
	while IFS= read -r path; do
		target="$TARGET_TREE/$path"
		old="$transaction/old/$path"
		new="$transaction/new/$path"
		if [ ! -e "$new" ]; then
			mv "$target" "$new" || {
				failed=1
				continue
			}
		fi
		if [ -e "$old" ]; then
			mv "$old" "$target" || failed=1
		fi
	done <"$transaction/reverse"
	awk '{paths[NR]=$0} END {for (i=NR; i>0; i--) print paths[i]}' "$transaction/created-dirs" >"$transaction/reverse" || return 1
	while IFS= read -r path; do
		[ ! -d "$TARGET_TREE/$path" ] || rmdir "$TARGET_TREE/$path" ||
			failed=1
	done <"$transaction/reverse"
	return "$failed"
}

# Publication relies on renames. Refuse paths whose mounts would cause
# mv to fall back to copying data between filesystems.
check_overlay_filesystem() {
	typeset path existing
	set -- "$transaction"
	while IFS= read -r path; do
		existing="$TARGET_TREE/$path"
		while [ ! -e "$existing" ]; do
			existing=${existing%/*}
		done
		set -- "$@" "$existing"
	done <"$transaction/entries"
	if ! LC_ALL=C df -P "$@" | awk '
		NR == 2 { filesystem = $1 }
		NR > 2 && $1 != filesystem { different = 1 }
		END { exit (NR < 2 || different) }
	'; then
		error "Overlay requires one filesystem for staging and destination paths"
		return 1
	fi
}

publish_overlay() {
	typeset path target new old
	LC_ALL=C sort -u "$transaction/directories" >"$transaction/dirs" ||
		return 1
	LC_ALL=C sort -u "$transaction/plan" >"$transaction/entries" || return 1
	check_overlay_filesystem || return 1
	while IFS= read -r path; do
		print -r -- "$path" >>"$transaction/created-dirs" || return 1
		case "$path" in
		.wip-changes) mkdir "$TARGET_TREE/$path" || return 1 ;;
		*) mkdir -m 755 "$TARGET_TREE/$path" || return 1 ;;
		esac
	done <"$transaction/dirs"
	while IFS= read -r path; do
		target="$TARGET_TREE/$path"
		new="$transaction/new/$path"
		old="$transaction/old/$path"
		mkdir -p "${old%/*}" || return 1
		print -r -- "$path" >>"$transaction/started" || return 1
		[ ! -e "$target" ] || mv "$target" "$old" || return 1
		mv "$new" "$target" || return 1
	done <"$transaction/entries"
}

overlay_selection() (
	typeset port transaction lock="$TARGET_TREE/.wip-overlay.lock"
	typeset publishing=0
	for port; do validate_port_path "$port" || return 1; done
	if [ ! -f "$TARGET_TREE/Makefile" ] ||
		[ ! -d "$TARGET_TREE/infrastructure" ]; then
		error "Not an OpenBSD ports tree: $TARGET_TREE"
		return 1
	fi
	mkdir "$lock" || {
		error "Overlay lock exists: $lock"
		return 1
	}
	trap '
		trap "" HUP INT TERM
		if [ "$publishing" -eq 1 ] && [ ! -f "$transaction/committed" ]; then
			if ! rollback_overlay; then
				error "Rollback incomplete. Inspect $transaction and retain $lock"
				exit 1
			fi
		fi
		rmdir "$lock"
	' EXIT
	trap 'exit 1' HUP INT TERM
	[ ! -L "$TARGET_TREE/.wip-backups" ] || return 1
	mkdir -p "$TARGET_TREE/.wip-backups" || return 1
	transaction=$(mktemp -d "$TARGET_TREE/.wip-backups/overlay.XXXXXXXX") ||
		return 1
	log "Overlay transaction: $transaction"
	for port in plan directories started created-dirs; do
		: >"$transaction/$port" || return 1
	done
	plan_directory .wip-changes || return 1
	copy_user_list "$transaction" "$@" || return 1
	printf '%s\n' "$@" >"$transaction/selection" || return 1
	LC_ALL=C sort -u "$transaction/selection" >"$transaction/ports" ||
		return 1
	while IFS= read -r port; do
		stage_port "$port" || return 1
	done <"$transaction/ports"
	publishing=1
	publish_overlay || return 1
	: >"$transaction/committed" || return 1
	log "Overlay published. Previous paths are under $transaction/old"
)

# Merge only accounts belonging to the selected ports (or all local ports
# when no scope is given). Never replace the cloned tree's registry with our
# potentially older upstream snapshot.
copy_user_list() {
	typeset transaction=$1
	shift
	typeset registry="$TARGET_TREE/infrastructure/db/user.list" stage ports mode
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
	if [ "$#" -gt 0 ]; then
		ports=$(printf '%s\n' "$@")
	else
		ports=$(list_all_directories) || return 1
	fi
	mkdir -p "$transaction/new/infrastructure/db" || return 1
	stage="$transaction/new/infrastructure/db/user.list"
	if ! awk -v ports="$ports" '
		BEGIN {
			FS = "\t"
			n = split(ports, paths, /[[:space:]]+/)
			for (i = 1; i <= n; i++)
				if (paths[i] != "") present[paths[i]] = 1
		}
		function trim(value) {
			sub(/^[ \t]+/, "", value)
			sub(/[ \t]+$/, "", value)
			return value
		}
		# The registry aligns columns with tabs but leaves some cells empty.
		# Keep non-empty tab fields and split the first one into id and user.
		function parse(   value, n, i, fields, iduser) {
			n = 0
			for (i = 1; i <= NF; i++) {
				value = trim($i)
				if (value != "") fields[++n] = value
			}
			pid = puser = pgroup = pport = ""
			if (n < 2) return 0
			split(fields[1], iduser, /[ \t]+/)
			if (iduser[1] !~ /^[0-9]+$/) return 0
			pid = iduser[1]
			puser = iduser[2]
			if (n >= 3) {
				pgroup = fields[2]
				pport = fields[3]
				for (i = 4; i <= n; i++) pport = pport " " fields[i]
			} else {
				pport = fields[2]
			}
			return 1
		}
		function localport(path,   n, i, token, pos, prefix, names, j, count, toks) {
			path = trim(path)
			# Expand one brace group, for example net/{monero,monero-lws}.
			pos = index(path, "{")
			if (pos && substr(path, length(path)) == "}") {
				prefix = substr(path, 1, pos - 1)
				count = split(substr(path, pos + 1, length(path) - pos - 1), names, ",")
				for (j = 1; j <= count; j++)
					if ((prefix names[j]) in present) return 1
			}
			# A row may list several ports separated by commas.
			n = split(path, toks, ",")
			for (i = 1; i <= n; i++) {
				token = trim(toks[i])
				if (token in present) return 1
			}
			return 0
		}
		FILENAME == ARGV[1] {
			if (parse() && localport(pport)) {
				ids[++total] = pid
				rows[pid] = $0
				users[pid] = puser
				groups[pid] = pgroup
			}
			next
		}
		{
			if (parse()) {
				for (id in rows) {
					if ((pid == id && (puser != users[id] || pgroup != groups[id])) || (pid != id && ((puser != "" && puser == users[id]) || (pgroup != "" && pgroup == groups[id])))) {
						print "Account ID/name conflict for local port: " rows[id] > "/dev/stderr"
						bad = 1
					}
				}
				seen[pid] = 1
			}
			print
		}
		END {
			if (bad) exit 1
			for (i = 1; i <= total; i++)
				if (!(ids[i] in seen)) print rows[ids[i]]
		}
	' user.list "$registry" >"$transaction/merged-registry"; then
		rm -f "$transaction/merged-registry"
		error "User registry unchanged; resolve conflicting port IDs first."
		return 1
	fi
	if ! cmp -s "$registry" "$transaction/merged-registry"; then
		cp -p "$registry" "$stage" || return 1
		mode=$(find "$stage" -perm -0200 -print) || return 1
		chmod u+w "$stage" || return 1
		cat "$transaction/merged-registry" >"$stage" || return 1
		[ -n "$mode" ] || chmod u-w "$stage" || return 1
		print -r -- infrastructure/db/user.list >>"$transaction/plan"
	fi
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

usage() {
	print -r -- "Usage: $0 --list | --copy-only TREE [category/port ...] | --bootstrap NEW_TREE"
}

main() {
	case "${1:-}" in
	"" | --help)
		usage
		;;
	--list)
		[ "$#" -eq 1 ] || {
			usage >&2
			return 2
		}
		move_to_wip_openbsd_ports || return 1
		list_all_directories
		;;
	--copy-only)
		[ "$#" -ge 2 ] || {
			usage >&2
			return 2
		}
		TARGET_TREE=$(canonical_target_tree "$2") || return 1
		shift 2
		move_to_wip_openbsd_ports || return 1
		if [ "$#" -eq 0 ]; then
			typeset ports port
			ports=$(list_all_directories) || return 1
			while IFS= read -r port; do
				set -- "$@" "$port"
			done <<EOF
$ports
EOF
		fi
		overlay_selection "$@"
		;;
	--bootstrap)
		[ "$#" -eq 2 ] || {
			usage >&2
			return 2
		}
		bootstrap_tree "$2"
		;;
	*)
		usage >&2
		return 2
		;;
	esac
}

main "$@"
