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

use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp   qw(tempdir);
use Getopt::Long qw(GetOptions);

my $apply = 0;
my $mode  = '';

GetOptions(
    'apply'  => \$apply,
    'help|h' => sub { usage(); },
) or usage();

$mode = shift @ARGV // '';
usage()
  unless $mode =~
/^(?:list-deps|sync-upstream|sync-deps|normalize-patches|normalize-incs|normalize-cabals|all)$/;
usage() if @ARGV;

my $script_dir       = script_dir();
my $repo_root        = $script_dir;
my $simplexmq_dir    = File::Spec->catdir( $repo_root, 'simplexmq' );
my $simplex_chat_dir = File::Spec->catdir( $repo_root, 'simplex-chat' );
my @tmpdirs;
my %ports = (
    simplexmq => {
        dir  => $simplexmq_dir,
        inc  => File::Spec->catfile( $simplexmq_dir, 'simplexmq.inc' ),
        incs => [
            File::Spec->catfile( $simplexmq_dir, 'simplexmq.inc' ),
            File::Spec->catfile( $simplexmq_dir, 'simplexmq.distfiles.inc' ),
        ],
        makefile => File::Spec->catfile( $simplexmq_dir, 'Makefile' ),
        cabal    =>
          File::Spec->catfile( $simplexmq_dir, 'files', 'simplexmq.cabal' ),
        project =>
          File::Spec->catfile( $simplexmq_dir, 'files', 'cabal.project.local' ),
        projects => [
            File::Spec->catfile(
                $simplexmq_dir, 'files', 'cabal.project.local.postgresql'
            )
        ],
        cabal_rel => 'simplexmq.cabal',
        repo      => 'https://github.com/simplex-chat/simplexmq.git',
        branch    => 'stable',
    },
    'simplex-chat' => {
        dir  => $simplex_chat_dir,
        inc  => File::Spec->catfile( $simplex_chat_dir, 'simplex-chat.inc' ),
        incs => [
            File::Spec->catfile( $simplex_chat_dir, 'simplex-chat.inc' ),
            File::Spec->catfile(
                $simplex_chat_dir, 'simplex-chat.distfiles.inc'
            ),
        ],
        makefile => File::Spec->catfile( $simplex_chat_dir, 'Makefile' ),
        cabal    => File::Spec->catfile(
            $simplex_chat_dir, 'files', 'simplex-chat.cabal'
        ),
        project => File::Spec->catfile(
            $simplex_chat_dir, 'files', 'cabal.project.local'
        ),
        projects => [
            File::Spec->catfile(
                $simplex_chat_dir, 'files',
                'cabal.project.local.postgresql'
            )
        ],
        cabal_rel => 'simplex-chat.cabal',
        repo      => 'https://github.com/simplex-chat/simplex-chat.git',
        branch    => 'stable',
    },
);

sub usage {
    print <<"USAGE";
Usage: $0 [--apply] [list-deps|sync-upstream|sync-deps|normalize-patches|normalize-incs|normalize-cabals|all]
  list-deps          Compare local pins against upstream GitHub cabal constraints.
  sync-upstream      Copy upstream GitHub cabal files into files/ and update cabal.project.local files.
  sync-deps          Sync shared version pins from simplexmq.inc into simplex-chat.inc.
  normalize-patches  Rename patch files to path-derived OpenBSD names.
  normalize-incs     Reorder .inc files with GitHub pins first, then Hackage.
  normalize-cabals   Reorder cabal.project.local package/constraint blocks.
  all                Run sync-upstream, normalize-patches, normalize-incs, normalize-cabals and sync-deps.
  --apply             Make changes instead of printing a dry run.
USAGE
    exit 1;
}

sub log_msg {
    my ($msg) = @_;
    print "[sync-simplex-ports] $msg\n";
}

sub script_dir {
    my $dir = File::Spec->rel2abs( dirname($0) );
    return $dir;
}

sub read_assignments {
    my ($file) = @_;
    open my $fh, '<', $file or die "open $file: $!";
    my @pairs;
    while ( my $line = <$fh> ) {
        next unless $line =~ /^([A-Z0-9_]+)\s*=\s*(.*?)\s*$/;
        push @pairs, [ $1, $2 ];
    }
    close $fh;
    return @pairs;
}

sub read_makefile_version {
    my ($file) = @_;
    open my $fh, '<', $file or die "open $file: $!";
    while ( my $line = <$fh> ) {
        next unless $line =~ /^\s*V\s*=\s*(\S+)/;
        close $fh;
        return $1;
    }
    close $fh;
    die "no V assignment found in $file";
}

sub read_cabal_version {
    my ($file) = @_;
    open my $fh, '<', $file or die "open $file: $!";
    while ( my $line = <$fh> ) {
        next unless $line =~ /^\s*version:\s*(\S+)/i;
        close $fh;
        return $1;
    }
    close $fh;
    die "no version field found in $file";
}

sub assignments_hash {
    my ($file) = @_;
    my %h;
    for my $pair ( read_assignments($file) ) {
        my ( $k, $v ) = @$pair;
        $h{$k} = $v;
    }
    return %h;
}

sub inc_sort_key {
    my ($var) = @_;
    my $rank = ( $var =~ /_(?:COMMIT|TAG)$/ ) ? 0 : 1;
    return ( $rank, lc $var, $var );
}

sub normalize_inc_file {
    my ($file) = @_;
    return unless -f $file;

    open my $fh, '<', $file or die "open $file: $!";
    my @lines = <$fh>;
    close $fh;

    my @preamble;
    my @pending;
    my @blocks;
    my $seen_assignment = 0;

    for my $line (@lines) {
        if ( $line =~ /^([A-Z0-9_]+)\s*=\s*(.*?)\s*$/ ) {
            push @blocks,
              {
                var   => $1,
                lines => [ @pending, $line ],
              };
            @pending         = ();
            $seen_assignment = 1;
        }
        else {
            if ($seen_assignment) {
                push @pending, $line;
            }
            else {
                push @preamble, $line;
            }
        }
    }

    return unless @blocks;

    my @sorted = sort {
        my @ak = inc_sort_key( $a->{var} );
        my @bk = inc_sort_key( $b->{var} );
        $ak[0] <=> $bk[0] || $ak[1] cmp $bk[1] || $ak[2] cmp $bk[2]
    } @blocks;

    my @out = @preamble;
    for my $block (@sorted) {
        push @out, @{ $block->{lines} };
    }
    push @out, @pending if @pending;

    write_lines_if_changed( $file, \@out );
}

sub package_versions_from_inc {
    my ($file) = @_;
    my %versions;
    for my $pair ( read_assignments($file) ) {
        my ( $k, $v ) = @$pair;
        next if $k =~ /_(?:REV|COMMIT)$/;
        my $pkg = var_to_package_name($k);
        next unless defined $pkg;
        $versions{ lc $pkg } = $v;
    }
    return %versions;
}

sub have_git {
    open my $fh, '-|', 'git', '--version' or return 0;
    my $line = <$fh>;
    close $fh;
    return defined $line && $line =~ /^git version /;
}

sub upstream_cabal {
    my ($port) = @_;
    my $cfg = $ports{$port} or die "unknown port $port";

    if ( !have_git() ) {
        log_msg("git not found; using local $cfg->{cabal} for $port");
        return $cfg->{cabal};
    }

    my $tmp =
      tempdir( "sync-simplex-$port-XXXXXXXX", TMPDIR => 1, CLEANUP => 1 );
    push @tmpdirs, $tmp;
    my $clone = File::Spec->catdir( $tmp, $port );
    my @cmd   = (
        'git',        'clone', '--depth', '1', '--branch', $cfg->{branch},
        $cfg->{repo}, $clone
    );
    if ( system(@cmd) != 0 ) {
        log_msg("git clone failed for $port; using local $cfg->{cabal}");
        return $cfg->{cabal};
    }

    my $cabal = File::Spec->catfile( $clone, $cfg->{cabal_rel} );
    if ( !-f $cabal ) {
        log_msg(
"missing $cfg->{cabal_rel} in upstream $port; using local $cfg->{cabal}"
        );
        return $cfg->{cabal};
    }
    return $cabal;
}

sub write_lines_if_changed {
    my ( $file, $lines_ref ) = @_;
    my @old;
    if ( -f $file ) {
        open my $in, '<', $file or die "open $file: $!";
        @old = <$in>;
        close $in;
    }
    return 0 if join( '', @old ) eq join( '', @$lines_ref );
    return 1 unless $apply;

    my $tmpname = $file . '.tmp';
    open my $out, '>', $tmpname or die "open $tmpname: $!";
    print {$out} @$lines_ref;
    close $out;
    rename $tmpname, $file or die "rename $tmpname -> $file: $!";
    return 1;
}

sub update_makefile_version {
    my ( $file, $wanted ) = @_;
    open my $in, '<', $file or die "open $file: $!";
    my @lines = <$in>;
    close $in;

    my $changed = 0;
    for my $line (@lines) {
        if ( $line =~ /^\s*V\s*=/ ) {
            my $new = "V = $wanted\n";
            $changed = 1 if $line ne $new;
            $line    = $new;
            last;
        }
    }
    return 0 unless $changed;
    write_lines_if_changed( $file, \@lines );
    return 1;
}

sub var_to_package_name {
    my ($var) = @_;
    return undef if $var =~ /_(?:REV|COMMIT)$/;
    my $name = lc $var;
    $name =~ s/_v$//;
    $name =~ s/_/-/g;
    $name =~ s/([a-z])([A-Z])/$1-$2/g;
    return $name;
}

sub parse_cabal_constraints {
    my ($file) = @_;
    open my $fh, '<', $file or die "open $file: $!";

    my %specs;
    my $in_build_depends = 0;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^\s*build-depends:/ ) {
            $in_build_depends = 1;
            $line =~ s/^\s*build-depends:\s*//;
        }
        elsif ( $in_build_depends && $line !~ /^\s*[, ]/ ) {
            $in_build_depends = 0;
        }

        next unless $in_build_depends;
        $line =~ s/^\s*,\s*//;
        my @parts = split /,/, $line;
        for my $part (@parts) {
            $part =~ s/^\s+|\s+$//g;
            next unless length $part;
            next if $part =~ /^--/;
            if ( $part =~ /^([A-Za-z0-9_.-]+)\s*(.*)$/ ) {
                my ( $pkg, $spec ) = ( lc $1, $2 // '' );
                $spec =~ s/^\s+|\s+$//g;
                next if $pkg eq 'base';
                if ( length $spec ) {
                    my %seen = map { $_ => 1 } @{ $specs{$pkg} // [] };
                    push @{ $specs{$pkg} }, $spec unless $seen{$spec};
                }
            }
        }
    }
    close $fh;
    return %specs;
}

sub split_version {
    my ($v) = @_;
    return map { 0 + $_ } split /\./, $v;
}

sub version_cmp {
    my ( $a, $b ) = @_;
    my @a   = split_version($a);
    my @b   = split_version($b);
    my $max = @a > @b ? @a : @b;
    for my $i ( 0 .. $max - 1 ) {
        my $av = $a[$i] // 0;
        my $bv = $b[$i] // 0;
        return $av <=> $bv if $av != $bv;
    }
    return 0;
}

sub satisfies_spec {
    my ( $version, $spec ) = @_;
    return 1 if !defined $spec || $spec eq '';

    my @clauses = split /\|\|/, $spec;
  CLAUSE:
    for my $clause (@clauses) {
        my @parts = grep { length } map { s/^\s+|\s+$//gr } split /\s*&&\s*/,
          $clause;
        my $ok = 1;
        for my $part (@parts) {
            if ( $part =~ /^==\s*([0-9.]+)$/ ) {
                $ok &&= version_cmp( $version, $1 ) == 0;
            }
            elsif ( $part =~ /^==\s*([0-9.]+)\.\*$/ ) {
                my $prefix = $1 . '.';
                $ok &&= $version eq $1 || index( $version, $prefix ) == 0;
            }
            elsif ( $part =~ /^>=\s*([0-9.]+)$/ ) {
                $ok &&= version_cmp( $version, $1 ) >= 0;
            }
            elsif ( $part =~ /^>\s*([0-9.]+)$/ ) {
                $ok &&= version_cmp( $version, $1 ) > 0;
            }
            elsif ( $part =~ /^<=\s*([0-9.]+)$/ ) {
                $ok &&= version_cmp( $version, $1 ) <= 0;
            }
            elsif ( $part =~ /^<\s*([0-9.]+)$/ ) {
                $ok &&= version_cmp( $version, $1 ) < 0;
            }
            elsif ( $part =~ /^~=\s*([0-9.]+)$/ ) {
                my $prefix = $1;
                $ok &&= index( $version, $prefix ) == 0;
            }
            else {
                next CLAUSE;
            }
            last unless $ok;
        }
        return 1 if $ok;
    }
    return 0;
}

sub show_dep_diff {
    for my $port ( sort keys %ports ) {
        my %pins           = assignments_hash( $ports{$port}->{inc} );
        my $upstream_cabal = upstream_cabal($port);
        my %specs          = parse_cabal_constraints($upstream_cabal);
        my $make_v         = read_makefile_version( $ports{$port}->{makefile} );
        my $cabal_v        = read_cabal_version($upstream_cabal);

        print "### $port\n";
        print join( "\t",
            'UPSTREAM',
            $ports{$port}->{repo},
            $ports{$port}->{branch} ),
          "\n";
        print join( "\t",
            'MAKEFILE_V', $make_v, $cabal_v,
            ( $make_v eq $cabal_v ? 'OK' : 'MISMATCH' ) ),
          "\n";

        if ( $port eq 'simplex-chat' && exists $pins{SIMPLEXMQ_V} ) {
            my $server_make_v = read_makefile_version(
                File::Spec->catfile( $simplexmq_dir, 'Makefile' ) );
            my $linked = $pins{SIMPLEXMQ_V};
            print join( "\t",
                'SIMPLEXMQ_V', $linked, $server_make_v,
                ( $linked eq $server_make_v ? 'OK' : 'MISMATCH' ) ),
              "\n";
        }
        for my $var ( sort keys %pins ) {
            next if $var eq 'V';
            my $pkg = var_to_package_name($var);
            next unless defined $pkg;
            next unless exists $specs{$pkg};
            my $local    = $pins{$var};
            my $upstream = join( ' || ', @{ $specs{$pkg} } );
            my $ok = satisfies_spec( $local, $upstream ) ? 'OK' : 'MISMATCH';
            print join( "\t", $var, $local, $upstream, $ok ), "\n";
        }
    }
}

sub sync_project_local {
    my ( $port, $project ) = @_;
    my $cfg      = $ports{$port} or die "unknown port $port";
    my %versions = package_versions_from_inc( $cfg->{inc} );
    my $changes  = 0;

    open my $in, '<', $project or die "open $project: $!";
    my @lines = <$in>;
    close $in;

    for my $line (@lines) {
        if ( $line =~
/^(\s*packages:\s+(?:\.\.\/)?)([A-Za-z0-9_.-]+)-([0-9][A-Za-z0-9_.-]*)\s*$/
          )
        {
            my ( $prefix, $pkg, $current ) = ( $1, lc $2, $3 );
            next unless exists $versions{$pkg};
            my $wanted = $versions{$pkg};
            next if $current eq $wanted;
            $line = $prefix . $2 . '-' . $wanted . "\n";
            $changes++;
        }
        elsif ( $line =~
/^(\s*constraints:\s+)([A-Za-z0-9_.-]+)\s*==\s*([0-9][A-Za-z0-9_.-]*)\s*$/
          )
        {
            my ( $prefix, $pkg, $current ) = ( $1, lc $2, $3 );
            next unless exists $versions{$pkg};
            my $wanted = $versions{$pkg};
            next if $current eq $wanted;
            $line = $prefix . $2 . ' == ' . $wanted . "\n";
            $changes++;
        }
    }

    my $pruned =
      prune_project_packages_to_direct( $port, $cfg->{cabal}, \@lines );
    if ($pruned) {
        log_msg("pruned non-direct packages from $project: $pruned");
        $changes += $pruned;
    }

    $changes += normalize_project_local_lines( \@lines );

    if ($changes) {
        if ($apply) {
            my $tmpname = $project . '.tmp';
            open my $out, '>', $tmpname or die "open $tmpname: $!";
            print {$out} @lines;
            close $out;
            rename $tmpname, $project or die "rename $tmpname -> $project: $!";
        }
        else {
            log_msg("would update $project");
        }
    }
    log_msg("project.local entries examined for $port: $changes");
}

sub direct_deps_from_cabal {
    my ($cabal_file) = @_;
    my %specs = parse_cabal_constraints($cabal_file);
    return map { lc $_ => 1 } keys %specs;
}

sub package_name_from_packages_token {
    my ($token) = @_;
    my $name = $token;
    $name =~ s{^\.\./}{};
    $name =~ s{/$}{};
    $name =~ s/-[0-9][A-Za-z0-9_.-]*$//;
    return lc $name;
}

sub prune_project_packages_to_direct {
    my ( $port, $cabal_file, $lines_ref ) = @_;
    my %direct = direct_deps_from_cabal($cabal_file);
    my @out;
    my $removed = 0;

    for my $line (@$lines_ref) {
        if ( $line =~ /^\s*packages:\s+(\S+)\s*$/ ) {
            my $token = $1;
            if ( $token ne '.' && $token =~ /-[0-9][A-Za-z0-9_.-]*$/ ) {
                my $pkg = package_name_from_packages_token($token);
                if ( !exists $direct{$pkg} ) {
                    $removed++;
                    next;
                }
            }
        }
        push @out, $line;
    }

    return 0 if !$removed;
    @$lines_ref = @out;
    return $removed;
}

sub project_local_sort_key {
    my ($line) = @_;
    if ( $line =~
        /^\s*packages:\s+(?:\.\.\/)?([A-Za-z0-9_.-]+)-[0-9][A-Za-z0-9_.-]*\s*$/
      )
    {
        return ( lc $1, lc $line );
    }
    if ( $line =~
        /^\s*constraints:\s+([A-Za-z0-9_.-]+)\s*==\s*[0-9][A-Za-z0-9_.-]*\s*$/ )
    {
        return ( lc $1, lc $line );
    }
    return ( lc $line, lc $line );
}

sub normalize_project_local_lines {
    my ($lines_ref) = @_;
    my @lines       = @$lines_ref;
    my $changes     = 0;

    for ( my $i = 0 ; $i <= $#lines ; $i++ ) {
        next
          unless $lines[$i] =~ /^\s*(packages|constraints):\s+/;
        my $kind = $1;
        my $j    = $i;
        $j++ while $j <= $#lines
          && $lines[$j] =~ /^\s*\Q$kind\E:\s+/;
        my @block  = @lines[ $i .. $j - 1 ];
        my @sorted = sort {
            my @ak = project_local_sort_key($a);
            my @bk = project_local_sort_key($b);
            $ak[0] cmp $bk[0] || $ak[1] cmp $bk[1]
        } @block;
        if ( join( '', @block ) ne join( '', @sorted ) ) {
            @lines[ $i .. $j - 1 ] = @sorted;
            $changes++;
        }
        $i = $j - 1;
    }

    @$lines_ref = @lines;
    return $changes;
}

sub sync_project_locals {
    my ($port) = @_;
    my $cfg = $ports{$port} or die "unknown port $port";
    sync_project_local( $port, $cfg->{project} );
    for my $project ( @{ $cfg->{projects} || [] } ) {
        next unless -f $project;
        sync_project_local( $port, $project );
    }
}

sub spec_candidate_versions {
    my ($spec) = @_;
    my %seen;
    my @candidates;
    while ( $spec =~ /(?:==|>=|<=|>|<|~=)\s*([0-9]+(?:\.[0-9]+)+)(\.\*)?/g ) {
        my ( $ver, $wildcard ) = ( $1, $2 );
        if ($wildcard) {
            my $expanded = $ver . '.0';
            push @candidates, $expanded unless $seen{$expanded}++;
        }
        push @candidates, $ver unless $seen{$ver}++;
    }
    return @candidates;
}

sub package_versions_across_ports {
    my ($pkg) = @_;
    my %versions;
    for my $port ( keys %ports ) {
        my %pins = assignments_hash( $ports{$port}->{inc} );
        for my $var ( keys %pins ) {
            my $name = var_to_package_name($var);
            next unless defined $name && lc($name) eq lc($pkg);
            $versions{ $pins{$var} } = 1;
        }
    }
    return sort { version_cmp( $b, $a ); } keys %versions;
}

sub sync_inc_with_cabal_constraints {
    my ( $port, $cabal_file ) = @_;
    my $cfg   = $ports{$port} or die "unknown port $port";
    my %specs = parse_cabal_constraints($cabal_file);

    open my $in, '<', $cfg->{inc} or die "open $cfg->{inc}: $!";
    my @lines = <$in>;
    close $in;

    my $changes = 0;
    for my $line (@lines) {
        next unless $line =~ /^([A-Z0-9_]+)\s*=\s*(.*?)\s*$/;
        my ( $name, $current ) = ( $1, $2 );
        my $pkg = var_to_package_name($name);
        next unless defined $pkg;
        next unless exists $specs{$pkg};
        my $spec = join( ' || ', @{ $specs{$pkg} } );
        next if satisfies_spec( $current, $spec );

        my %seen;
        my @candidates = grep { !$seen{$_}++ } (
            package_versions_across_ports($pkg),
            spec_candidate_versions($spec)
        );
        my ($wanted) = grep { satisfies_spec( $_, $spec ) } @candidates;
        if ( !defined $wanted ) {
            log_msg(
                "skip $name: no candidate version satisfies upstream $spec");
            next;
        }
        next if $wanted eq $current;
        my $old = $current;
        $line =~ s/^(\Q$name\E\s*=\s*).*$/$1$wanted/;
        $line .= "\n" unless $line =~ /\n\z/;
        log_msg("sync $cfg->{inc} $name: $old -> $wanted (requires $spec)");
        $changes++;
    }

    if ($changes) {
        write_lines_if_changed( $cfg->{inc}, \@lines );
        sync_project_locals($port);
    }
}

sub sync_upstream {
    my $changes = 0;
    for my $port ( sort keys %ports ) {
        my $cfg            = $ports{$port};
        my $upstream_cabal = upstream_cabal($port);
        my $make_v         = read_makefile_version( $cfg->{makefile} );
        my $cabal_v        = read_cabal_version($upstream_cabal);
        my $status         = $make_v eq $cabal_v ? 'OK' : 'MISMATCH';
        log_msg(
"$port Makefile V=$make_v upstream $cfg->{cabal_rel} version=$cabal_v $status"
        );

        if ( $make_v ne $cabal_v
            && update_makefile_version( $cfg->{makefile}, $cabal_v ) )
        {
            log_msg( ( $apply ? 'updated ' : 'would update ' )
                . "$cfg->{makefile} V: $make_v -> $cabal_v" );
            $changes++;
        }

        open my $in, '<', $upstream_cabal or die "open $upstream_cabal: $!";
        my @lines = <$in>;
        close $in;

        if ( write_lines_if_changed( $cfg->{cabal}, \@lines ) ) {
            log_msg(
                ( $apply ? 'updated ' : 'would update ' ) . $cfg->{cabal} );
            $changes++;
        }
        sync_inc_with_cabal_constraints( $port, $upstream_cabal );
        sync_project_locals($port);
    }
    log_msg(
        (
            $apply
            ? 'upstream files changed: '
            : 'upstream files needing change: '
        )
        . $changes
    );
}

sub sync_dep_vars {
    my $mq_file = File::Spec->catfile( $simplexmq_dir, 'simplexmq.inc' );
    my $chat_file =
      File::Spec->catfile( $simplex_chat_dir, 'simplex-chat.inc' );
    my %mq         = assignments_hash($mq_file);
    my %chat_specs = parse_cabal_constraints( upstream_cabal('simplex-chat') );

    open my $in, '<', $chat_file or die "open $chat_file: $!";
    my @lines = <$in>;
    close $in;

    my %targets = %mq;
    $targets{SIMPLEXMQ_V} = delete $targets{V} if exists $targets{V};

    my $changes = 0;
    for my $name ( sort keys %targets ) {
        next unless grep { /^\Q$name\E\s*=/ } @lines;
        my ($current) = map { /^\Q$name\E\s*=\s*(.*?)\s*$/ ? $1 : () } @lines;
        next unless defined $current;
        my $wanted = $targets{$name};
        my $pkg    = var_to_package_name($name);
        if ( defined $pkg && exists $chat_specs{$pkg} ) {
            my $spec = join( ' || ', @{ $chat_specs{$pkg} } );
            if ( !satisfies_spec( $wanted, $spec ) ) {
                log_msg(
"skip $name: simplexmq $wanted does not satisfy simplex-chat upstream $spec"
                );
                next;
            }
        }
        next if $current eq $wanted;
        log_msg("sync $name: $current -> $wanted");
        $changes++;
        if ($apply) {
            for my $line (@lines) {
                $line =~ s/^\Q$name\E\s*=.*/$name =\t\t$wanted/;
            }
        }
    }

    if ($apply) {
        my $tmpname = $chat_file . '.tmp';
        open my $out, '>', $tmpname or die "open $tmpname: $!";
        print {$out} @lines;
        close $out;
        rename $tmpname, $chat_file or die "rename $tmpname -> $chat_file: $!";
        sync_project_locals('simplex-chat') if $changes;
    }
    else {
        log_msg('dry run only; rerun with --apply to write changes');
    }
    log_msg("shared pins examined: $changes");
}

sub patch_name_from_header {
    my ($patch_file) = @_;
    open my $fh, '<', $patch_file or die "open $patch_file: $!";
    my $src_path = '';
    while ( my $line = <$fh> ) {
        next unless $line =~ /^---\s+(\S+)/;
        $src_path = $1;
        last;
    }
    close $fh;
    return '' if $src_path eq '' || $src_path eq '/dev/null';
    $src_path =~ s{^[ab]/}{};
    if ( $src_path =~ m{^([^/]+)/(.+)$} ) {
        my ( $head, $tail ) = ( $1, $2 );
        $head =~ s/-[0-9].*$//;
        $src_path = join( '_', $head, $tail );
        $src_path =~ tr{/\.}{__};
        return "patch-$src_path";
    }
    $src_path =~ tr{/.}{__};
    return "patch-$src_path";
}

sub normalize_patch_dir {
    my ($port_dir) = @_;
    my $patch_dir = File::Spec->catdir( $port_dir, 'patches' );
    return unless -d $patch_dir;

    opendir my $dh, $patch_dir or die "opendir $patch_dir: $!";
    my @patches =
      sort grep { /^patch-/ && -f File::Spec->catfile( $patch_dir, $_ ) }
      readdir $dh;
    closedir $dh;

    for my $patch (@patches) {
        my $full     = File::Spec->catfile( $patch_dir, $patch );
        my $new_name = patch_name_from_header($full);
        next if $new_name eq '' || $new_name eq $patch;
        my $new_full = File::Spec->catfile( $patch_dir, $new_name );
        if ( -e $new_full ) {
            log_msg("skip existing $new_full");
            next;
        }
        log_msg("$patch -> $new_name");
        rename $full, $new_full or die "rename $full -> $new_full: $!";
    }
}

sub normalize_patches {
    normalize_patch_dir($simplexmq_dir);
    normalize_patch_dir($simplex_chat_dir);
}

sub normalize_incs {
    for my $port ( sort keys %ports ) {
        for my $file ( @{ $ports{$port}->{incs} || [] } ) {
            normalize_inc_file($file);
        }
    }
}

sub normalize_cabals {
    for my $port ( sort keys %ports ) {
        my $cfg = $ports{$port} or next;
        sync_project_local( $port, $cfg->{project} ) if -f $cfg->{project};
        for my $project ( @{ $cfg->{projects} || [] } ) {
            next unless -f $project;
            sync_project_local( $port, $project );
        }
    }
}

if ( $mode eq 'list-deps' ) {
    show_dep_diff();
}
elsif ( $mode eq 'sync-upstream' ) {
    sync_upstream();
}
elsif ( $mode eq 'sync-deps' ) {
    sync_dep_vars();
}
elsif ( $mode eq 'normalize-patches' ) {
    normalize_patches();
}
elsif ( $mode eq 'normalize-incs' ) {
    normalize_incs();
}
elsif ( $mode eq 'normalize-cabals' ) {
    normalize_cabals();
}
elsif ( $mode eq 'all' ) {
    sync_upstream();
    normalize_patches();
    normalize_incs();
    normalize_cabals();
    sync_dep_vars();
}
