#!/usr/bin/env perl
#
# Copyright (c) 2026 David David Uhden Collado <david@uhden.dev>
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
#
# Merge cabal-bundler output from multiple executables into a single
# MODCABAL_MANIFEST, skipping vendored packages and injecting extras.
#
# Environment:
#   SKIP   comma-separated package names to exclude (e.g. aeson,socks)
#   EXTRA  comma-separated name:version:revision triplets to inject
#
# Usage:
#   env SKIP=... EXTRA=... perl cabal-deps-merge.pl inc1 inc2 > cabal.inc

use strict;
use warnings;

my %skip = map { $_ => 1 } split /,/, $ENV{SKIP} // '';
my %seen;

for my $dep ( split /,/, $ENV{EXTRA} // '' ) {
    next unless length $dep;
    my ( $n, $v, $r ) = split /:/, $dep;
    next                    if $skip{$n};
    $seen{"$n\t$v\t$r"} = 1 if defined $r;
} ## end for my $dep ( split /,/...)

while (<>) {
    next unless /^\s+(\S+)\s+(\S+)\s+(\d+)\s*\\?$/;
    my ( $n, $v, $r ) = ( $1, $2, $3 );
    next if $skip{$n};
    $seen{"$n\t$v\t$r"} = 1;
} ## end while (<>)

my @deps = sort keys %seen;
print "MODCABAL_MANIFEST\t= \\\n";
for my $i ( 0 .. $#deps ) {
    print "\t$deps[$i]";
    print $i == $#deps ? "\n" : "\t\\\n";
}
