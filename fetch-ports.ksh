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

# Remove ports tree files
rm -f /tmp/ports.tar.gz
rm -f /tmp/SHA256.sig

# Remove the ports directory
rm -rf /usr/ports

# Fetch the OpenBSD version
VERSION=$(uname -r)
SHORT_VERSION=$(echo "$VERSION" | cut -c 1,3)

# Directories for ports configuration
WRKOBJDIR="/usr/obj/ports"
DISTDIR="/usr/distfiles"
PACKAGE_REPOSITORY="/usr/packages"

# Fetch ports tree files from mirrors
cd /tmp || exit 1
ftp "https://cdn.openbsd.org/pub/OpenBSD/$VERSION/ports.tar.gz"
ftp "https://cdn.openbsd.org/pub/OpenBSD/$VERSION/SHA256.sig"

# Verify the integrity of the ports.tar.gz file
signify -Cp "/etc/signify/openbsd-$SHORT_VERSION-base.pub" -x SHA256.sig ports.tar.gz

# Extract the ports tree into /usr
cd /usr || exit 1
tar xzf /tmp/ports.tar.gz

# Remove the contents of the /usr/ports/net/i2pd directory
rm -rf /usr/ports/net/i2pd

# Move to the wip-openbsd-ports directory
wip_openbsd_ports_dir=$(find / -type d -name "wip-openbsd-ports" 2>/dev/null | head -n 1)
if [ -z "$wip_openbsd_ports_dir" ]; then
    echo "wip-openbsd-ports directory not found."
    exit 1
fi
cd "$wip_openbsd_ports_dir" || exit 1

# Copy the contents of the current directory's net directory to /usr/ports/net
cp -R ./* /usr/ports/net/

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
