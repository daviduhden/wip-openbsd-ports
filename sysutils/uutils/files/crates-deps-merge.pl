#!/usr/bin/env perl
#
# Copyright (c) 2026 David David Uhden Collado <david@uhden.dev>
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
#
# Merge the crates.io dependencies of several Cargo.lock files into a
# single MODCARGO_CRATES list.  The port builds several independent
# uutils projects, so the devel/cargo module's single-lock target cannot
# be used.  Path, git and local dependencies are skipped: the module can
# only vendor registry crates.
#
# Environment:
#   SKIP  comma-separated crate names to exclude
#
# Usage:
#   env SKIP=... perl crates-deps-merge.pl \
#       Cargo.lock extra/Cargo.lock ... > crates.inc

use strict;
use warnings;

my %skip = map { $_ => 1 } split /,/, $ENV{SKIP} // '';
my %seen;

for my $file (@ARGV) {
    open my $fh, '<', $file or die "$file: $!";
    my ( $name, $version, $registry, $in_package ) = ( undef, undef, undef, 0 );
    while ( my $line = <$fh> ) {
        if ( $line =~ /^\[\[package\]\]/ ) {
            record( $name, $version, $registry );
            ( $name, $version, $registry, $in_package ) =
              ( undef, undef, undef, 1 );
        } elsif ( $line =~ /^\[/ ) {
            # Any other table (for example [metadata]) ends the package.
            record( $name, $version, $registry );
            ( $name, $version, $registry, $in_package ) =
              ( undef, undef, undef, 0 );
        } elsif ($in_package) {
            if ( $line =~ /^name\s*=\s*"([^"]+)"/ ) {
                $name = $1;
            } elsif ( $line =~ /^version\s*=\s*"([^"]+)"/ ) {
                $version = $1;
            } elsif (
                $line =~
                m{^source\s*=\s*"registry\+https://github\.com/rust-lang/crates\.io-index"}
              )
            {
                $registry = 1;
            }
        }
    } ## end while ( my $line = <$fh> )
    record( $name, $version, $registry );
    close $fh;
} ## end for my $file (@ARGV)

print "MODCARGO_CRATES +=\t$_\n" for sort keys %seen;

# A package only counts when it comes from crates.io; everything else is
# provided by DIST_TUPLE or lives in the source tree.
sub record {
    my ( $name, $version, $registry ) = @_;
    return unless defined $name && defined $version && $registry;
    return if $skip{$name};
    $seen{"$name\t$version"} = 1;
}
