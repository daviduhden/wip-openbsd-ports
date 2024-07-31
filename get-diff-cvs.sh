#!/bin/sh

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

# Function to show script usage
usage() {
    echo "Usage: $0 <directory>"
    exit 1
}

# Check if an argument was passed
if [ $# -ne 1 ]; then
    usage
fi

DIRECTORY=$1

# Check if the directory exists in the repository
if [ ! -d "$DIRECTORY" ]; then
    echo "The directory '$DIRECTORY' does not exist in the repository."
    exit 1
fi

# Function to generate diff for the entire history
diff_entire_history() {
    cvs diff -u > "${DIRECTORY}_diff_entire_history.diff"
    echo "Diff for the entire history saved in ${DIRECTORY}_diff_entire_history.diff"
}

# Function to generate diff between two revisions
diff_between_revisions() {
    echo "Enter the tag of the first revision:"
    read REVISION1
    echo "Enter the tag of the second revision:"
    read REVISION2
    cvs diff -r "$REVISION1" -r "$REVISION2" > "${DIRECTORY}_diff_${REVISION1}_${REVISION2}.diff"
    echo "Diff between $REVISION1 and $REVISION2 saved in ${DIRECTORY}_diff_${REVISION1}_${REVISION2}.diff"
}

# Menu to select the option
echo "Select an option:"
echo "1. Generate diff for the entire history"
echo "2. Generate diff between two specific revisions"
read OPTION

case $OPTION in
    1)
        diff_entire_history
        ;;
    2)
        diff_between_revisions
        ;;
    *)
        echo "Invalid option"
        usage
        ;;
esac

exit 0