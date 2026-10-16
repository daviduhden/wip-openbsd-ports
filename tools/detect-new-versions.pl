#!/usr/bin/env perl
#
# detect-new-versions.pl - report the ports of this collection whose upstream
# release is newer than the version pinned in the port.
#
# The upstream version is taken from the registry that matches how the port
# fetches its source:
#   * Go modules  -> https://proxy.golang.org/<module>/@v/list
#   * PyPI        -> https://pypi.org/pypi/<project>/json
#   * GitHub      -> https://api.github.com/repos/<owner>/<repo>/tags
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
use File::Find     qw(find);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX      qw(strftime);
use JSON::PP;

my $self = File::Spec->rel2abs($0);
my $WIP  = dirname( dirname($self) );    # <wip>/tools/detect-new-versions.pl
my $LOGDIR;
my $ONLY   = '';
my $DRYRUN = 0;
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
if ( -e $REPORT || -l $REPORT ) {
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
    return undef unless defined $pid;
    if ( !$pid ) {
        open( STDERR, '>', '/dev/null' ) or POSIX::_exit(127);
        exec { $command[0] } @command    or POSIX::_exit(127);
    }
    my $body = do { local $/ = undef; <$pipe> };
    return undef unless close $pipe;
    return defined $body && length $body ? $body : undef;
}

sub fetch {
    my ($url) = @_;
    return undef if $DRYRUN;
    my $body;
    if ( eval { require HTTP::Tiny; 1 } ) {
        my $r = HTTP::Tiny->new( agent => $UA, timeout => 30, verify_SSL => 1 )
          ->get($url);
        $body = $r->{content} if $r->{success};
    }
    if ( !defined $body && -x '/usr/bin/ftp' ) {
        $body = fetch_command( '/usr/bin/ftp', '-o', '-', '-V', $url );
        $body = undef if defined $body && $body eq '';
    }
    if ( !defined $body && -x '/usr/bin/curl' ) {
        $body =
          fetch_command( '/usr/bin/curl', '-fsSL', '--max-time', '30', $url );
        $body = undef if defined $body && $body eq '';
    }
    return $body;
}

sub jget {
    my ($url) = @_;
    my $body = fetch($url);
    return undef unless defined $body;
    return eval { decode_json($body) };
}

sub pvar {
    my ( $text, $name ) = @_;
    return $text =~ /^\Q$name\E[ \t]*=[ \t]*(.*)$/m ? $1 : undef;
}

sub expand {
    my ( $s, $vals ) = @_;
    return undef unless defined $s;
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
    return undef unless @v;
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

# each fetcher returns ($latest_within_limits, $overall_latest)

sub go_versions {
    my ( $mod, @lims ) = @_;
    my $j = jget( 'https://proxy.golang.org/' . esc_mod($mod) . '/@latest' );
    my $overall = ref $j eq 'HASH' && $j->{Version} ? $j->{Version} : undef;
    my $latest  = $overall;
    if (@lims) {
        my $body =
          fetch( 'https://proxy.golang.org/' . esc_mod($mod) . '/@v/list' );
        my @v = defined $body
          ? grep { /^v?\d+(?:\.\d+)*$/ } split /\s+/, $body
          : ();
        $latest = vmax( grep { in_limits( $_, @lims ) } @v ) // $overall;
    }
    return ( $latest, $overall );
}

sub pypi_versions {
    my ( $name, @lims ) = @_;
    my $j = jget("https://pypi.org/pypi/$name/json");
    return ( undef, undef ) unless ref $j eq 'HASH' && ref $j->{info} eq 'HASH';
    my $overall = $j->{info}{version};
    my @v       = grep { /^v?\d+(?:\.\d+)*$/ }
      keys %{ ref $j->{releases} eq 'HASH' ? $j->{releases} : {} };
    my $latest = @lims ? vmax( grep { in_limits( $_, @lims ) } @v ) : $overall;
    $latest //= $overall;
    return ( $latest, $overall );
}

sub gh_versions {
    my ( $acc, $proj, $tagpat, @lims ) = @_;
    my $j = jget("https://api.github.com/repos/$acc/$proj/tags?per_page=100");
    return ( undef, undef ) unless ref $j eq 'ARRAY';
    my $prefix = '';
    if ( defined $tagpat ) { ($prefix) = $tagpat =~ /^([^0-9]*)/; }
    $prefix = '' unless defined $prefix;
    my @v;
    for my $t ( map { $_->{name} }
        grep { ref $_ eq 'HASH' && defined $_->{name} && !ref $_->{name} } @$j )
    {
        next if length $prefix && index( $t, $prefix ) != 0;
        ( my $rest = $t ) =~ s/^\Q$prefix\E//;
        next unless $rest =~ /^v?\d+(?:\.\d+)*$/;
        push @v, $t;
    }
    my $overall = vmax(@v);
    my $latest  = @lims ? vmax( grep { in_limits( $_, @lims ) } @v ) : $overall;
    return ( $latest, $overall );
}

sub find_ports {
    my @ports;
    opendir( my $dh, $WIP ) or die "$WIP: $!";
    for my $cat ( sort readdir $dh ) {
        next if $cat =~ /^\./;
        next
          if $cat eq 'logs'
          || $cat eq 'tools'
          || $cat eq 'audit'
          || $cat eq 'infrastructure';
        my $catdir = File::Spec->catdir( $WIP, $cat );
        next unless -d $catdir;
        find(
            {
                wanted => sub {
                    return unless basename($_) eq 'Makefile';
                    return if $File::Find::name =~ m{/(CVS|files|patches)/};
                    my $rel = File::Spec->abs2rel( $File::Find::name, $WIP );
                    ( my $dir = dirname($rel) ) =~ s{^\./}{};
                    push @ports, $dir;
                },
                no_chdir => 1,
            },
            $catdir
        );
    }
    closedir $dh or die "closedir: $!";
    return sort @ports;
}

# ---------------------------------------------------------------- main

my @ports = find_ports();
@ports = grep { $_ eq $ONLY } @ports if length $ONLY;
out( "# new versions report - " . strftime( '%Y-%m-%d %H:%M:%S', localtime ) );
out("# collection: $WIP");
out("");

my ( @outdated, @pinned, @unknown );
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

    my ( $kind, $cur, $latest, $overall );
    if ( defined $vals{MODGO_MODNAME} && length $vals{MODGO_MODNAME} ) {
        $kind = 'go';
        $cur  = $vals{MODGO_VERSION};
        ( $latest, $overall ) = go_versions( $vals{MODGO_MODNAME}, @lims );
    }
    elsif ( defined $vals{GH_ACCOUNT} && defined $vals{GH_PROJECT} ) {
        $kind = 'gh';
        $cur  = $vals{GH_TAGNAME};
        ( $latest, $overall ) =
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
        ( $latest, $overall ) = pypi_versions( $name, @lims );
    }
    else {
        $kind = 'manual';
        $cur  = $vals{V} // $vals{VERSION};
    }

    my $status = '??';
    if ( defined $latest && defined $cur ) {
        my $c = vnorm($cur);
        my $l = vnorm($latest);
        $c =~ s/^[A-Za-z-]*v//;
        $l =~ s/^[A-Za-z-]*v//;
        if ( $c eq $l ) {
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
    elsif ( $kind eq 'manual' ) {
        push @unknown, $p;
    }
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
      . scalar(@unknown) );
out("report: $REPORT");
close STDOUT or die "close stdout: $!";
exit( @outdated ? 1 : 0 );
