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

# Check that an argument was provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 file"
  exit 1
fi

# Check that the file exists
if [ ! -f "$1" ]; then
  echo "The file $1 does not exist."
  exit 1
fi

# Determine the operating system
OS=$(uname)

# Calculate the SHA256 of the file
if [ "$OS" = "Linux" ]; then
  SHA256SUM=$(sha256sum "$1" | awk '{print $1}')
elif [ "$OS" = "OpenBSD" ]; then
  SHA256SUM=$(sha256 -q "$1")
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

# Get the file size in bytes
if [ "$OS" = "Linux" ]; then
  SIZE=$(stat -c%s "$1")
elif [ "$OS" = "OpenBSD" ]; then
  SIZE=$(stat -f%z "$1")
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

# Display the results
echo "SHA256: $SHA256SUM"
echo "Size in bytes: $SIZE"