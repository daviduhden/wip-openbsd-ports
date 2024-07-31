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
    echo "Usage: $0"
    exit 1
}

# Check if CVS is installed
if ! command -v cvs &> /dev/null; then
    echo "CVS is not installed. Please install CVS to use this script."
    exit 1
fi

# Clone the ports repository
clone_repository() {
    cvs -qd anoncvs@anoncvs.fr.openbsd.org:/cvs checkout -P ports
}

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

# List subdirectories in the ports directory
list_ports_subdirectories() {
    echo "Select a subdirectory in ports where the directory will be copied:"
    select SUBDIRECTORY in ports/*/; do
        if [ -n "$SUBDIRECTORY" ]; then
            echo "You selected $SUBDIRECTORY"
            SUBDIRECTORY=${SUBDIRECTORY%/}  # Remove trailing slash
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Copy the selected directory to ports
copy_directory() {
    TARGET_DIR="$SUBDIRECTORY/$DIRECTORY"
    if [ -d "$TARGET_DIR" ]; then
        echo "Directory $TARGET_DIR already exists. Replacing it."
        rm -rf "$TARGET_DIR"
    fi
    cp -r "$DIRECTORY" "$SUBDIRECTORY/"
    echo "Directory $DIRECTORY copied to $SUBDIRECTORY/"
}

# Generate a diff of the changes
generate_diff() {
    cd ports
    cvs diff -u > "../${DIRECTORY}_diff.diff"
    cd ..
    echo "Diff of the changes saved in ${DIRECTORY}_diff.diff"
}

# Main function
main() {
    clone_repository
    list_directories
    list_ports_subdirectories
    copy_directory
    generate_diff
}

# Run the main function
main

exit 0