#!/bin/sh

# Fetch the OpenBSD version
VERSION=$(uname -r)
SHORT_VERSION=$(echo $VERSION | cut -c 1,3)

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

# Configure the ports system in /etc/mk.conf
echo "Configuring the ports system in /etc/mk.conf..."
{
    echo "WRKOBJDIR=$WRKOBJDIR"
    echo "DISTDIR=$DISTDIR"
    echo "PACKAGE_REPOSITORY=$PACKAGE_REPOSITORY"
} >> /etc/mk.conf

echo "Configuration complete. The ports tree has been installed and configured successfully."

# Removing the default i2pd port
if [ -d "/usr/ports/net/i2pd" ]; then
    echo "Removing the default i2pd port..."
    rm -rf /usr/ports/net/i2pd
fi

# Installing the new ports in /usr/ports/net/
echo "Installing the new ports in /usr/ports/net/..."
find . -maxdepth 2 ! -name ".*" ! -name "*.sh" -print | cpio -pdm /usr/ports/net/

echo "The new ports have been installed successfully."
