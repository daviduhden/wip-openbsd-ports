#!/bin/ksh

# Copyright (c) 2024-2025 David Uhden Collado <david@uhden.dev>
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

# Verify that the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print "This script must be run as root." >&2
        exit 1
    fi
}

# Function to permanently set the CVSROOT environment variable if not already set
set_cvsroot() {
    if ! grep -q "export CVSROOT=anoncvs@anoncvs.eu.openbsd.org:/cvs" ~/.profile; then
        print "export CVSROOT=anoncvs@anoncvs.eu.openbsd.org:/cvs" >> ~/.profile
        print "CVSROOT variable added to ~/.profile"
    else
        print "CVSROOT variable already exists in ~/.profile"
    fi
    export CVSROOT="anoncvs@anoncvs.eu.openbsd.org:/cvs"
}

# Function to remove the ports directory
remove_ports_directory() {
    rm -rf /usr/ports
}

# Function to checkout the ports tree using CVS (removes old tree first)
checkout_ports_tree() {
    cd /usr || exit 1
    remove_ports_directory
    cvs -qd anoncvs@anoncvs.eu.openbsd.org:/cvs checkout -P ports
}

# Ask if user wants to copy from wip-openbsd-ports (optional)
ask_copy_from_wip() {
    print "Do you want to copy a directory from 'wip-openbsd-ports' into /usr/ports?"
    select ANSWER in "Yes" "No"; do
        case "$ANSWER" in
            Yes) DO_COPY=1; break ;;
            No)  DO_COPY=0; break ;;
            *)   print "Invalid selection. Please try again." ;;
        esac
    done
}

# Function to change directory to the wip-openbsd-ports directory
move_to_wip_openbsd_ports() {
    wip_openbsd_ports_dir=$(find / -type d -name "wip-openbsd-ports" 2>/dev/null | head -n 1)
    if [ -z "$wip_openbsd_ports_dir" ]; then
        print "wip-openbsd-ports directory not found."
        exit 1
    fi
    cd "$wip_openbsd_ports_dir" || exit 1
}

# Function to list directories in wip-openbsd-ports and select one
list_directories() {
    print "Select a directory to copy from wip-openbsd-ports:"
    select DIRECTORY in */; do
        if [ -n "$DIRECTORY" ]; then
            print "You selected $DIRECTORY"
            DIRECTORY=${DIRECTORY%/}  # Remove the trailing slash
            break
        else
            print "Invalid selection. Please try again."
        fi
    done
}

# Function to choose the target tree (mirrors your style; here only /usr/ports)
choose_target_tree() {
    options=""
    [ -d /usr/ports ] && options="$options /usr/ports"
    if [ -z "$options" ]; then
        print "No destination trees available under /usr."
        exit 1
    fi
    print "Select the target tree for the copy:"
    select TARGET_TREE in $options; do
        if [ -n "$TARGET_TREE" ]; then
            print "You selected $TARGET_TREE"
            break
        else
            print "Invalid selection. Please try again."
        fi
    done
}

# Function to list subdirectories (categories) in the chosen tree and select one
list_tree_subdirectories() {
    print "Select a subdirectory in $TARGET_TREE where the directory will be copied:"
    select SUBDIRECTORY in "$TARGET_TREE"/*/; do
        if [ -n "$SUBDIRECTORY" ]; then
            print "You selected $SUBDIRECTORY"
            SUBDIRECTORY=${SUBDIRECTORY%/}  # Remove the trailing slash
            break
        else
            print "Invalid selection. Please try again."
        fi
    done
}

# Function to copy the selected directory to the chosen subdirectory in target tree
copy_directory() {
    TARGET_DIR="$SUBDIRECTORY/$DIRECTORY"
    if [ -d "$TARGET_DIR" ]; then
        print "Directory $TARGET_DIR already exists. Removing files except 'CVS' directories."
        find "$TARGET_DIR" -mindepth 1 ! -name "CVS" -exec rm -rf {} +
    fi
    cp -R "$DIRECTORY" "$SUBDIRECTORY/"
    print "Directory $DIRECTORY copied to $SUBDIRECTORY/"
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

    print "User 'user' created with password: $PASSWORD"
}

# Function to configure doas
configure_doas() {
    cp /etc/examples/doas.conf /etc/doas.conf
    print "permit keepenv persist user" >> /etc/doas.conf
    print "doas configured successfully. /etc/doas.conf updated."
}

# Ports build configuration
WRKOBJDIR="/usr/obj/ports"
DISTDIR="/usr/distfiles"
PACKAGE_REPOSITORY="/usr/packages"

# Function to configure the ports system in /etc/mk.conf
configure_ports_system() {
    rm -f /etc/mk.conf
    print "Configuring the ports system in /etc/mk.conf..."
    {
        print "WRKOBJDIR=$WRKOBJDIR"
        print "DISTDIR=$DISTDIR"
        print "PACKAGE_REPOSITORY=$PACKAGE_REPOSITORY"
        print "SUDO=doas"
    } >> /etc/mk.conf
    print "Configuration complete. The ports tree has been installed and configured successfully."
}

# Main function
main() {
    check_root
    set_cvsroot
    checkout_ports_tree
    ask_copy_from_wip
    if [ "${DO_COPY:-0}" -eq 1 ]; then
        move_to_wip_openbsd_ports
        list_directories
        choose_target_tree
        list_tree_subdirectories
        copy_directory
    else
        print "Skipping copy from wip-openbsd-ports."
    fi
    create_user_with_random_password
    configure_doas
    configure_ports_system
}

# Execute the main function
main