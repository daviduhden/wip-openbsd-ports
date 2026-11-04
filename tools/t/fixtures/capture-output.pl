#!/usr/bin/env perl
# Emit a large stdout stream and one stderr marker for the capture test.
use strict;
use warnings;

print 'x' x 100_000;
print STDERR 'stderr-marker';
