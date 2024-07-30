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
    git diff HEAD -- "$DIRECTORY" > "${DIRECTORY}_diff_entire_history.diff"
    echo "Diff for the entire history saved in ${DIRECTORY}_diff_entire_history.diff"
}

# Function to generate diff between two commits
diff_between_commits() {
    echo "Enter the hash of the first commit:"
    read COMMIT1
    echo "Enter the hash of the second commit:"
    read COMMIT2
    git diff "$COMMIT1" "$COMMIT2" -- "$DIRECTORY" > "${DIRECTORY}_diff_${COMMIT1}_${COMMIT2}.diff"
    echo "Diff between $COMMIT1 and $COMMIT2 saved in ${DIRECTORY}_diff_${COMMIT1}_${COMMIT2}.diff"
}

# Menu to select the option
echo "Select an option:"
echo "1. Generate diff for the entire history"
echo "2. Generate diff between two specific commits"
read OPTION

case $OPTION in
    1)
        diff_entire_history
        ;;
    2)
        diff_between_commits
        ;;
    *)
        echo "Invalid option"
        usage
        ;;
esac

exit 0
