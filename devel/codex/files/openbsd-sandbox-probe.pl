#!/usr/bin/env perl
# Perform one filesystem or network probe for openbsd-sandbox-regress.pl.
#
# Usage:
#   openbsd-sandbox-probe.pl exit0
#   openbsd-sandbox-probe.pl write PATH
#   openbsd-sandbox-probe.pl mkdir PATH
#   openbsd-sandbox-probe.pl metadata
#   openbsd-sandbox-probe.pl fchown
#   openbsd-sandbox-probe.pl connect HOST PORT
#
# The probe is a separate program so that the regression driver does not
# embed Perl source in command arguments.  Each operation exits non-zero on
# failure and leaves the caller to decide whether the result was expected.

use strict;
use warnings;

my $operation = shift @ARGV // '';

if ( $operation eq 'exit0' ) {
    exit 0;
}

if ( $operation eq 'write' ) {
    my $path = shift @ARGV // die "usage: write PATH\n";
    open my $handle, '>', $path or die "open $path: $!\n";
    print {$handle} 'changed' or die "write $path: $!\n";
    close $handle            or die "close $path: $!\n";
    exit 0;
}

if ( $operation eq 'mkdir' ) {
    my $path = shift @ARGV // die "usage: mkdir PATH\n";
    mkdir $path or die "mkdir $path: $!\n";
    exit 0;
}

if ( $operation eq 'metadata' ) {
    chmod 0600, 'allowed' or die "chmod: $!\n";
    utime undef, undef, 'allowed' or die "utime: $!\n";
    exit 0;
}

if ( $operation eq 'fchown' ) {
    open my $handle, '+<', 'allowed' or die "open: $!\n";
    my $gid = ( split / /, $) )[0];
    chown $<, $gid, $handle or die "fchown: $!\n";
    close $handle              or die "close: $!\n";
    exit 0;
}

if ( $operation eq 'connect' ) {
    require IO::Socket::INET;
    my $host = shift @ARGV // die "usage: connect HOST PORT\n";
    my $port = shift @ARGV // die "usage: connect HOST PORT\n";
    my $socket = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    ) or die "connect: $!\n";
    close $socket or die "close: $!\n";
    exit 0;
}

die "unknown probe: $operation\n";
