#!/bin/ksh

# Check the repository patch format without applying the patch.
# Usage: check-patch-style.ksh patch-file ...

status=0

for file in "$@"; do
	if [ ! -f "$file" ]; then
		print -u2 "$file: not a regular file"
		status=1
		continue
	fi

	bytes=$(wc -c <"$file")
	stripped=$(LC_ALL=C tr -d '\r' <"$file" | wc -c)
	if [ "$bytes" -ne "$stripped" ]; then
		print -u2 "$file: CRLF line ending"
		status=1
	fi

	if ! awk -v file="$file" '
		function fail(message) {
			print file ": " message > "/dev/stderr"
			bad = 1
		}
		function check_hunk() {
			if (oc != oldc || nc != newc)
				fail("hunk at line " hline " counts -" oc " +" nc ", header says -" oldc " +" newc)
		}
		BEGIN {
			indexes = 0
			header = 1
			comment = 0
			minus = 0
			plus = 0
			in_hunk = 0
		}
		{
			if ($0 ~ /^Index: /) {
				indexes++
				header = 0
				path = substr($0, 8)
				if (path ~ /^\// || path ~ /(^|\/)\.\.?(\/|$)/)
					fail("Index path is not relative: " path)
				next
			}
			if (header) {
				if (length($0) > 72)
					fail("comment line " NR " exceeds 72 columns")
				if ($0 !~ /^[[:space:]]*$/)
					comment = 1
				next
			}
			if ($0 ~ /^@@ /) {
				if (in_hunk)
					check_hunk()
				split($0, parts, " ")
				oldspec = substr(parts[2], 2)
				newspec = substr(parts[3], 2)
				split(oldspec, oldparts, ",")
				split(newspec, newparts, ",")
				oldc = (2 in oldparts) ? oldparts[2] : 1
				newc = (2 in newparts) ? newparts[2] : 1
				oc = nc = 0
				in_hunk = 1
				seen_hunk = 1
				hline = NR
				next
			}
			if (in_hunk) {
				if ($0 ~ /^(Index: |diff )/) {
					check_hunk()
					in_hunk = 0
					next
				}
				if ($0 ~ /^\\/)
					next
				first = substr($0, 1, 1)
				if (first == "-")
					oc++
				else if (first == "+")
					nc++
				else if (first == " " || $0 == "") {
					oc++
					nc++
				} else {
					check_hunk()
					in_hunk = 0
				}
				next
			}
			if (!seen_hunk && $0 ~ /^--- /) {
				minus++
				label = substr($0, 5)
				if (label !~ /\.orig$/ && label != "/dev/null")
					fail("--- label is not .orig or /dev/null: " label)
			}
			if (!seen_hunk && $0 ~ /^\+\+\+ /) {
				plus++
				label = substr($0, 5)
				if (label ~ /^\/dev\/null$/)
					fail("+++ label may not be /dev/null")
			}
		}
		END {
			if (in_hunk)
				check_hunk()
			if (indexes != 1)
				fail("expected exactly one Index: line, found " indexes)
			if (!comment)
				fail("missing comment before Index:")
			if (minus != 1 || plus != 1)
				fail("expected one ---/+++ pair, found " minus "/" plus)
			exit bad ? 1 : 0
		}
	' "$file"; then
		status=1
	fi
done

exit $status
