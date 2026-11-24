#!/usr/bin/env perl
#
# detect-new-versions.pl - report the ports of this collection whose upstream
# release is newer than the version pinned in the port.
#
# The upstream version is taken from the registry that matches how the port
# fetches its source:
#   * Go modules  -> https://proxy.golang.org/<module>/@v/list
#   * PyPI        -> https://pypi.org/pypi/<project>/json
#   * GitHub      -> https://api.github.com/repos/<owner>/<repo>/releases
# Ports that fetch from anywhere else are reported as 'manual'.
#
# A port that carries "PORTROACH = limit:<regex>" only tracks the versions
# matching the regular expression (a major release its dependents pin, e.g.
# "LiteLLM requires filelock <4"): such a port is reported as 'pinned' when
# upstream only offers a newer out-of-limit release, and as 'OUTDATED' when a
# newer in-limit release exists.
#
# Nothing is downloaded or built: only the registry metadata is queried.  The
# report is written both to stdout and to $LOGDIR/report.txt.
#
# Usage: detect-new-versions.pl [--wip DIR] [--logdir DIR] [--only cat/port]
#
use strict;
use warnings;
use Getopt::Long   qw(GetOptions);
use File::Basename qw(dirname basename);
use File::Path     qw(make_path);
use FindBin        qw($RealBin);
use lib $RealBin;
use PortTools qw(inventory);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX      qw(strftime);
use JSON::PP;

my $self = File::Spec->rel2abs($0);
my $WIP  = dirname( dirname($self) );    # <wip>/tools/detect-new-versions.pl
my $LOGDIR;
my $ONLY   = '';
my $DRYRUN = 0;
my $helper = "$RealBin/../fetch-ports.ksh";
my $UA     = 'wip-newversions/1.0';

GetOptions(
    'wip=s'    => \$WIP,
    'logdir=s' => \$LOGDIR,
    'only=s'   => \$ONLY,
    'dry-run'  => \$DRYRUN,
    'help'     => sub { usage(0); },
) or usage(2);

$WIP = File::Spec->rel2abs($WIP);
$LOGDIR //= tempdir(
    'wip-newversions-' . strftime( '%Y%m%d-%H%M%S', localtime ) . '-XXXXXX',
    DIR => '/tmp' );
make_path($LOGDIR) unless -d $LOGDIR;
my $REPORT = "$LOGDIR/report.txt";
if ( -l $REPORT ) {
    die "refusing to replace symlink $REPORT\n";
}
if ( -e $REPORT ) {
    unlink $REPORT or die "unlink $REPORT: $!";
}

sub usage {
    my ($status) = @_;
    print <<"USAGE" or die "write stdout: $!";
detect-new-versions.pl - report ports whose upstream release is newer

  --wip DIR        wip ports collection (default: parent of this script's dir)
  --logdir DIR     log directory (default: /tmp/wip-newversions-<timestamp>-<random>)
  --only CAT/PORT  check only this port
  --dry-run        do not query the registries
  --help           this message

Ports with "PORTROACH = limit:<regex>" are checked against the versions that
match the limit; a newer upstream release outside the limit is reported as
"pinned" instead of "OUTDATED".
USAGE
    exit $status;
}

sub out {
    my ($line) = @_;
    print "$line\n"               or die "write stdout: $!";
    open( my $fh, '>>', $REPORT ) or die "open $REPORT: $!";
    print {$fh} "$line\n"         or die "write $REPORT: $!";
    close $fh                     or die "close $REPORT: $!";
    return;
}

# fetch a URL, preferring HTTP::Tiny and falling back to OpenBSD ftp(1) (which
# handles https without IO::Socket::SSL); curl is accepted as a last resort
# List-form exec keeps registry metadata out of shell syntax. A failed client
# must not contribute partial JSON to the version report.
sub fetch_command {
    my (@command) = @_;
    my $pid = open( my $pipe, '-|' );
    return unless defined $pid;
    if ( !$pid ) {
        open( STDERR, '>', '/dev/null' ) or POSIX::_exit(127);
        exec { $command[0] } @command    or POSIX::_exit(127);
    }
    my $body = do { local $/ = undef; <$pipe> };
    return unless close $pipe;
    return defined $body && length $body ? $body : undef;
}

sub fetch {
    my ($url) = @_;
    return ( 'dry-run', undef ) if $DRYRUN;
    if ( eval { require HTTP::Tiny; 1 } ) {
        my $http =
          HTTP::Tiny->new( agent => $UA, timeout => 30, verify_SSL => 1 );
        my $tries = 0;
        while (1) {
            my $r = $http->get($url);
            return ( 'ok', $r->{content} ) if $r->{success};
            my $status = $r->{status} // 599;
            return ( 'absent', undef ) if $status == 404 || $status == 410;
            if (
                $status == 429
                || ( $status == 403
                    && ( $r->{headers}{'x-ratelimit-remaining'} // '' ) eq '0' )
              )
            {
                my $wait = $r->{headers}{'retry-after'} // '';
                return ( 'rate-limited', undef )
                  unless !$tries++ && $wait =~ /^[012]$/;
                sleep $wait;
                next;
            }
            if ( $status == 502 || $status == 503 || $status == 504 ) {
                return ( 'lookup-error', undef ) if $tries++;
                sleep 1;
                next;
            }
            return ( 'lookup-error', undef ) unless $status == 599;

            # OpenBSD's ftp can provide TLS when Perl lacks IO::Socket::SSL.
            last;
        }
    }
    for my $client ( [ '/usr/bin/ftp', '-o', '-', '-V' ],
        [ '/usr/bin/curl', '-fsSL', '--max-time', '30' ] )
    {
        next unless -x $client->[0];
        my $body = fetch_command( @$client, $url );
        return ( 'ok', $body ) if defined $body;
    }
    return ( 'lookup-error', undef );
}

sub jget {
    my ($url) = @_;
    my ( $status, $body ) = fetch($url);
    return ( $status, undef ) unless $status eq 'ok';
    my $json = eval { decode_json($body) };
    return ( 'lookup-error', undef ) if $@ || !defined $json;
    return ( 'ok',           $json );
}

sub pvar {
    my ( $text, $name ) = @_;
    if ( $text =~ /^\Q$name\E[ \t]*[:?]?=[ \t]*(.*)$/m ) {
        my $value = $1;
        $value =~ s/[ \t]+(?:#.*)?\z//;
        return $value;
    }
    return;
}

sub expand {
    my ( $s, $vals ) = @_;
    return unless defined $s;
    if ( defined $vals->{V} ) {
        my $vr = $vals->{V};
        $vr =~ s/\.[^.]*$// for ( 1 .. 2 );
        $s  =~ s/\$\{V:R:R\}/$vr/g;
    }
    my $prev;
    my $remaining = scalar( keys %{$vals} ) + 1;
    do {
        die "cyclic make variable expansion\n" unless $remaining--;
        $prev = $s;
        $s =~
s/\$\{([A-Za-z0-9_]+)\}/defined $vals->{$1} ? $vals->{$1} : "\${$1}"/ge;
        $s =~ s/\$([A-Za-z_])/defined $vals->{$1} ? $vals->{$1} : "\$$1"/ge;
    } while ( $s ne $prev );
    return $s;
}

sub esc_mod { my ($p) = @_; $p =~ s/([A-Z])/'!' . lc($1)/ge; return $p; }

sub vnorm { my ($v) = @_; $v =~ s/^[A-Za-z-]*v(?=\d)//; return $v; }

sub vparts {
    my ($v) = @_;
    return map { int $_ } ( $v =~ /(\d+)/g );
}

sub vcmp {
    my ( $a, $b ) = @_;
    my @x = vparts($a);
    my @y = vparts($b);
    my $n = @x > @y ? scalar(@x) : scalar(@y);
    for my $i ( 0 .. $n - 1 ) {
        my $d = ( $x[$i] // 0 ) - ( $y[$i] // 0 );
        return $d if $d;
    }
    return 0;
}

sub vmax {
    my (@v) = @_;
    return unless @v;
    my @s = sort { vcmp( $a, $b ) } @v;
    return $s[-1];
}

# PORTROACH limits: "limit:<regex>", possibly repeated, ":"-separated
sub limits_from {
    my ($portroach) = @_;
    return () unless defined $portroach;
    return ( $portroach =~ /(?:^|:)limit:([^:]+)/g );
}

sub in_limits {
    my ( $v, @lims ) = @_;
    return 1 unless @lims;
    for my $l (@lims) { return 1 if $v =~ /$l/; }
    return 0;
}

# Each backend returns the highest eligible version, the overall stable
# version, and a status that distinguishes an empty result from a failure.
sub select_versions {
    my ( $versions, $limits ) = @_;
    my $overall = vmax(@$versions);
    return ( undef, undef, 'no-release' ) unless defined $overall;
    my $eligible = vmax( grep { in_limits( $_, @$limits ) } @$versions );
    return ( $eligible, $overall, defined $eligible ? 'ok' : 'no-eligible' );
}

sub go_versions {
    my ( $mod, @lims ) = @_;
    my ( $status, $body ) =
      fetch( 'https://proxy.golang.org/' . esc_mod($mod) . '/@v/list' );
    return ( undef, undef, $status ) unless $status eq 'ok';
    my @versions = grep { /^v\d+\.\d+\.\d+(?:\+incompatible)?$/ } split /\s+/,
      $body;
    return select_versions( \@versions, \@lims );
}

sub pypi_versions {
    my ( $name,   @lims ) = @_;
    my ( $status, $j )    = jget("https://pypi.org/pypi/$name/json");
    return ( undef, undef, $status ) unless $status eq 'ok';
    return ( undef, undef, 'lookup-error' )
      unless ref $j eq 'HASH' && ref $j->{releases} eq 'HASH';
    my @versions = grep {
        my $files = $j->{releases}{$_};
        /^\d+(?:\.\d+)*$/
          && ref $files eq 'ARRAY'
          && grep { ref $_ eq 'HASH' && !$_->{yanked} } @$files;
    } keys %{ $j->{releases} };
    return select_versions( \@versions, \@lims );
}

sub gh_versions {
    my ( $acc, $proj, $tagpat, @lims ) = @_;
    my $prefix = $tagpat // '';
    $prefix =~ s/\d.*//;
    return ( undef, undef, 'manual' ) if $prefix =~ /\$/;
    my @versions;
    for my $page ( 1 .. 20 ) {
        my ( $status, $j ) = jget(
"https://api.github.com/repos/$acc/$proj/releases?per_page=100&page=$page"
        );
        return ( undef, undef, $status )        unless $status eq 'ok';
        return ( undef, undef, 'lookup-error' ) unless ref $j eq 'ARRAY';
        for my $release (@$j) {
            next
              unless ref $release eq 'HASH'
              && !$release->{draft}
              && !$release->{prerelease};
            my $tag = $release->{tag_name};
            next
              unless defined $tag && !ref $tag && index( $tag, $prefix ) == 0;
            my $version = substr( $tag, length $prefix );
            push @versions, $tag if $version =~ /^v?\d+(?:\.\d+)*$/;
        }
        return select_versions( \@versions, \@lims ) if @$j < 100;
    }
    return ( undef, undef, 'lookup-error' );
}

# ---------------------------------------------------------------- main

my @ports = inventory( $helper, $WIP );
@ports = grep { $_ eq $ONLY } @ports if length $ONLY;
die "--only $ONLY does not name an installable port\n"
  if length($ONLY) && !@ports;
out(    "# new versions report - "
      . strftime( '%Y-%m-%d %H:%M:%S', localtime )
      . ( $DRYRUN ? ' (dry-run)' : '' ) );
out("# collection: $WIP");
out("");

my ( @outdated, @pinned, @unknown, @failed );
for my $p (@ports) {
    my $mk = File::Spec->catfile( $WIP, split( m{/}, $p ), 'Makefile' );
    open( my $fh, '<', $mk ) or next;
    my $text = do { local $/ = undef; <$fh> // q{} };
    close $fh or die "close file: $!";

    my %vals;
    $vals{$_} = pvar( $text, $_ )
      for
      qw(V VERSION MODGO_MODNAME MODGO_VERSION MODPY_DISTV GH_ACCOUNT GH_PROJECT GH_TAGNAME);
    $vals{$_} = expand( $vals{$_}, \%vals ) for keys %vals;
    my @lims = limits_from( pvar( $text, 'PORTROACH' ) );

    my ( $kind, $cur, $latest, $overall, $lookup );
    if ( defined $vals{MODGO_MODNAME} && length $vals{MODGO_MODNAME} ) {
        $kind = 'go';
        $cur  = $vals{MODGO_VERSION};
        ( $latest, $overall, $lookup ) =
          go_versions( $vals{MODGO_MODNAME}, @lims );
    }
    elsif ( defined $vals{GH_ACCOUNT} && defined $vals{GH_PROJECT} ) {
        $kind = 'gh';
        $cur  = $vals{GH_TAGNAME};
        ( $latest, $overall, $lookup ) =
          gh_versions( $vals{GH_ACCOUNT}, $vals{GH_PROJECT}, $vals{GH_TAGNAME},
            @lims );
    }
    elsif ( defined $vals{MODPY_DISTV} && length $vals{MODPY_DISTV} ) {
        $kind = 'pypi';
        $cur  = $vals{MODPY_DISTV};
        my $distname = pvar( $text, 'DISTNAME' ) // '';
        my ($name) = $distname =~ /^([A-Za-z0-9_.+-]+?)-?\$\{/;
        $name = $vals{GH_PROJECT} // basename($p) unless defined $name;
        $name =~ s/[-_.]+/-/g;
        $name = lc $name;
        ( $latest, $overall, $lookup ) = pypi_versions( $name, @lims );
    }
    else {
        $kind   = 'manual';
        $lookup = 'manual';
        $cur    = $vals{V} // $vals{VERSION};
    }

    my $status = $lookup // 'manual';
    if ( defined $latest && defined $cur && $status eq 'ok' ) {
        my $c = vnorm($cur);
        my $l = vnorm($latest);
        $c =~ s/^[A-Za-z-]*v//;
        $l =~ s/^[A-Za-z-]*v//;
        if ( vcmp( $c, $l ) == 0 ) {
            my $o = defined $overall ? vnorm($overall) : undef;
            $o =~ s/^[A-Za-z-]*v// if defined $o;
            if ( defined $o && vcmp( $o, $c ) > 0 ) {
                $status = 'pinned';
                push @pinned, $p;
            }
            else { $status = 'ok'; }
        }
        elsif ( vcmp( $l, $c ) > 0 ) {
            $status = 'OUTDATED';
            push @outdated, [ $p, $kind, $cur, $latest ];
        }
        else {
            $status = 'AHEAD';
        }
    }
    elsif ( $status eq 'manual' ) {
        push @unknown, $p;
    }
    push @failed, $p if $status eq 'lookup-error' || $status eq 'rate-limited';
    out(
        sprintf(
            "%-9s %-6s %-42s %-18s -> %s",
            $status, $kind, $p,
            ( defined $cur    ? $cur    : '-' ),
            ( defined $latest ? $latest : '-' )
        )
    );
}

out("");
out(    "outdated: "
      . scalar(@outdated)
      . "   pinned: "
      . scalar(@pinned)
      . "   manual: "
      . scalar(@unknown)
      . "   lookup failures: "
      . scalar(@failed) );
out("report: $REPORT");
close STDOUT or die "close stdout: $!";
exit( @failed ? 2 : @outdated ? 1 : 0 );
