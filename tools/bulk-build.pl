#!/usr/bin/env perl
#
# bulk-build.pl - build every port of this wip collection against a clean
# OpenBSD ports tree checked out from CVS.
#
# For each port the script
#   1. refreshes a clean ports tree (CVS) and overlays the wip ports on it,
#   2. regenerates the generated manifests: distinfo ('make makesum') and, when
#      the port carries one, the module manifest (modules.inc via
#      'make modgo-gen-modules', crates.inc via 'make modcargo-gen-crates' or
#      cabal.inc via 'make cabal-inc'); with --update-plist an empty pkg/PLIST
#      is regenerated too,
#   3. installs the dependencies that are not part of this collection as
#      binary packages with 'pkg_add -u -Dsnap',
#   4. builds the ports in dependency order ('make install' by default), and
#   5. runs the port test target when the port has one ('make test').
#
# Every command's output is written to a per-port log and the run summary to
# $LOGDIR/summary.txt, both under /tmp by default.
#
# Usage: bulk-build.pl [--wip DIR] [--ports /usr/ports] [--jobs N]
#                      [--tests|--no-tests] [--update-plist] [--build install]
#                      [--only cat/port] [--skip-cvs|--no-refresh] [--dry-run]
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

my $self    = File::Spec->rel2abs($0);
my $WIP     = dirname( dirname($self) );             # <wip>/tools/bulk-build.pl
my $PORTS   = '/usr/ports';
my $CVSROOT = 'anoncvs@anoncvs.ca.openbsd.org:/cvs';
my $LOGDIR;
my $PKG_ADD  = 'pkg_add -u -Dsnap';
my $MAKE     = 'make';
my $JOBS     = 1;
my $TESTS    = 1;
my $PLIST    = 0;
my $REFRESH  = 1;
my $SKIPCVS  = 0;
my $BUILDTGT = 'install';
my $ONLY     = '';
my $DRYRUN   = 0;

GetOptions(
    'wip=s'         => \$WIP,
    'ports=s'       => \$PORTS,
    'cvsroot=s'     => \$CVSROOT,
    'logdir=s'      => \$LOGDIR,
    'pkg-add=s'     => \$PKG_ADD,
    'make=s'        => \$MAKE,
    'jobs=i'        => \$JOBS,
    'tests!'        => \$TESTS,
    'update-plist!' => \$PLIST,
    'refresh!'      => \$REFRESH,
    'skip-cvs'      => \$SKIPCVS,
    'build=s'       => \$BUILDTGT,
    'only=s'        => \$ONLY,
    'dry-run'       => \$DRYRUN,
    'help'          => sub { usage(0); },
) or usage(2);

$WIP = File::Spec->rel2abs($WIP);
die "--jobs must be a positive integer\n" if $JOBS <= 0;
$PORTS = File::Spec->rel2abs($PORTS);
$LOGDIR //=
  tempdir( 'wip-bulk-' . strftime( '%Y%m%d-%H%M%S', localtime ) . '-XXXXXX',
    DIR => '/tmp' );
make_path($LOGDIR) unless -d $LOGDIR;
my $MASTER  = "$LOGDIR/bulk-build.log";
my $SUMMARY = "$LOGDIR/summary.txt";
my $ENVM    = $JOBS > 1 ? "MAKE_JOBS=$JOBS " : "";

sub usage {
    my ($status) = @_;
    print <<"USAGE" or die "write stdout: $!";
bulk-build.pl - overlay the wip ports on a clean ports tree and bulk-build them

  --wip DIR         wip ports collection (default: parent of this script's dir)
  --ports DIR       ports tree to build in (default: /usr/ports)
  --cvsroot ROOT    CVS root (default: $CVSROOT)
  --logdir DIR      log directory (default: /tmp/wip-bulk-<timestamp>-<random>)
  --pkg-add CMD     command used for dependencies outside the collection
                    (default: "pkg_add -u -Dsnap")
  --jobs N          pass MAKE_JOBS=N to make (default: 1)
  --tests           run "make test" when the port has tests (default)
  --no-tests        do not run the port tests
  --update-plist    regenerate an empty pkg/PLIST with "make update-plist"
  --no-refresh      do not refresh the CVS tree before overlaying
  --skip-cvs        never touch CVS (use the tree as it is)
  --build TARGET    make target to build the ports (default: install)
  --only CAT/PORT   build only this port (no dependency ordering)
  --dry-run         log the commands without running them
  --help            this message
USAGE
    exit $status;
}

sub logmsg {
    my ($msg) = @_;
    my $line = strftime( '%H:%M:%S', localtime ) . " $msg\n";
    open( my $fh, '>>', $MASTER ) or die "open $MASTER: $!";
    print {$fh} $line             or die "write $MASTER: $!";
    close $fh                     or die "close $MASTER: $!";
    print $line                   or die "write stdout: $!";
    return;
}

# run a shell command, appending all its output to $log; returns the exit code
sub sh {
    my ( $log, $cmd ) = @_;
    logmsg("run: $cmd");
    return 0 if $DRYRUN;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ( $pid == 0 ) {
        open( STDOUT, '>>', $log )     or die "open $log: $!";
        open( STDERR, '>&', \*STDOUT ) or die "dup: $!";
        print {*STDOUT} "\n=== $cmd\n" or die "write $log: $!";
        exec( '/bin/sh', '-c', $cmd )  or POSIX::_exit(127);
    }
    my $waited;
    do { $waited = waitpid( $pid, 0 ); } while $waited == -1 && $!{EINTR};
    die "waitpid: $!" unless $waited == $pid;
    my $status = $?;
    my $rc     = ( $status & 127 ) ? 128 + ( $status & 127 ) : $status >> 8;
    logmsg( sprintf( "  exit %d%s", $rc, $rc ? " (see $log)" : "" ) );
    return $rc;
}

# capture a command's stdout (for "make show=VAR")
# Commands are intentional shell templates (--make/--pkg-add); data is quoted.
sub shell_quote {
    my ($value) = @_;
    $value =~ s/'/'"'"'/g;
    return "'$value'";
}

sub cap {
    my ($cmd) = @_;
    return '' if $DRYRUN;
    open( my $pipe, '-|', '/bin/sh', '-c', "$cmd 2>/dev/null" )
      or die "capture command: $!";
    my $out = do { local $/ = undef; <$pipe> };
    return '' unless close $pipe;
    chomp $out if defined $out;
    return defined $out ? $out : '';
}

sub portlog {
    my ($p) = @_;
    ( my $n = $p ) =~ s{/}{-}g;
    return "$LOGDIR/$n.log";
}

sub show_var {
    my ( $dir, $var ) = @_;
    my $qdir = shell_quote($dir);
    return cap("cd $qdir && $MAKE show=$var");
}

# every directory under the collection that carries a Makefile is a port
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

# dependencies of a port as port paths (cat/port), from the framework so that
# module-added dependencies are included
sub port_deps {
    my ($dir) = @_;
    my %deps;
    for my $var (qw(BUILD_DEPENDS LIB_DEPENDS RUN_DEPENDS TEST_DEPENDS)) {
        for my $tok ( split /\s+/, show_var( $dir, $var ) ) {
            $deps{$1} = 1 if $tok =~ m{^([A-Za-z0-9_.+-]+/[A-Za-z0-9_.+-]+)};
        }
    }
    return sort keys %deps;
}

sub ensure_tree {
    return if $SKIPCVS;
    my $qports   = shell_quote($PORTS);
    my $qcvsroot = shell_quote($CVSROOT);
    if ( !-d "$PORTS/CVS" ) {
        make_path($PORTS) unless -d $PORTS;
        logmsg("checking out a clean ports tree into $PORTS");
        sh( $MASTER, "cvs -qd $qcvsroot co -P -d $qports ports" ) == 0
          or die "CVS checkout failed\n";
    }
    elsif ($REFRESH) {
        logmsg("refreshing the CVS ports tree in $PORTS");
        sh( $MASTER, "cd $qports && cvs -qd $qcvsroot up -PAd" ) == 0
          or die "CVS update failed\n";
    }
    return;
}

sub sync_ports {
    my (@ports) = @_;
    my $has_rsync = length cap('command -v rsync');
    for my $p (@ports) {
        my $src = File::Spec->catdir( $WIP,   split m{/}, $p );
        my $dst = File::Spec->catdir( $PORTS, split m{/}, $p );
        make_path($dst) unless -d $dst;
        my $qsrc          = shell_quote("$src/");
        my $qsrc_contents = shell_quote("$src/.");
        my $qdst          = shell_quote("$dst/");
        my $cmd =
          $has_rsync
          ? "rsync -a --delete $qsrc $qdst"
          : "cp -Rp $qsrc_contents $qdst";
        sh( $MASTER, $cmd ) == 0 or die "port overlay failed: $p\n";
    }
    return;
}

sub topo_order {
    my (@ports) = @_;
    my %wip = map { $_ => 1 } @ports;
    my %deps;
    for my $p (@ports) {
        $deps{$p} = [ grep { $wip{$_} } port_deps("$PORTS/$p") ];
    }
    my ( %state, @order );
    my $visit;
    $visit = sub {
        my ($p) = @_;
        return if ( $state{$p} // 0 ) == 2;
        if ( ( $state{$p} // 0 ) == 1 ) {
            logmsg("dependency cycle at $p");
            return;
        }
        $state{$p} = 1;
        $visit->($_) for @{ $deps{$p} || [] };
        $state{$p} = 2;
        push @order, $p;
    };
    $visit->($_) for @ports;
    return @order;
}

# ---------------------------------------------------------------- main

logmsg("wip collection: $WIP");
logmsg("ports tree:     $PORTS");
logmsg("logs:           $LOGDIR");

my @all_ports = find_ports();
die "no ports found under $WIP\n" unless @all_ports;
my %wip   = map                  { $_ => 1 } @all_ports;
my @ports = length($ONLY) ? grep { $_ eq $ONLY } @all_ports : @all_ports;
logmsg( "ports to build: " . scalar(@ports) );

ensure_tree();
sync_ports(@ports);

my @order = length($ONLY) ? @ports : topo_order(@ports);
my ( %installed, %result );

for my $p (@order) {
    my $dir  = "$PORTS/$p";
    my $plog = portlog($p);
    my $qdir = shell_quote($dir);
    logmsg("=== $p");
    my $r = { manifests => '-', deps => '-', build => '-', test => 'skip' };

    # 1. generated manifests
    my $mrc = 0;
    $mrc |= sh( $plog, "cd $qdir && $ENVM$MAKE makesum" );
    if ( -e "$dir/modules.inc" ) {
        $mrc |=
          sh( $plog, "cd $qdir && $MAKE modgo-gen-modules > modules.inc" );
    }
    if ( -e "$dir/crates.inc" ) {
        $mrc |= sh( $plog,
"cd $qdir && { $MAKE modcargo-gen-crates-licenses || $MAKE modcargo-gen-crates; } > crates.inc"
        );
    }
    if ( -e "$dir/cabal.inc" ) {
        $mrc |= sh( $plog, "cd $qdir && $MAKE cabal-inc" );
    }
    if ( $PLIST && !-s "$dir/pkg/PLIST" ) {
        $mrc |= sh( $plog, "cd $qdir && $MAKE update-plist" );
    }
    $r->{manifests} = $mrc ? "FAIL($mrc)" : 'ok';

    # 2. dependencies: pkg_add the ones outside the collection
    my $drc = 0;
    for my $dep ( port_deps($dir) ) {
        next if $wip{$dep};
        next unless -d "$PORTS/$dep";
        next if $installed{$dep};
        my $pkg = show_var( "$PORTS/$dep", 'PKGNAME' );
        next unless length $pkg;
        my $qdep   = shell_quote("$PORTS/$dep");
        my $qpkg   = shell_quote($pkg);
        my $dep_rc = sh( $plog, "cd $qdep && $PKG_ADD $qpkg" );
        $drc |= $dep_rc;
        $installed{$dep} = 1 unless $dep_rc;
    }
    $r->{deps} = $drc ? "FAIL($drc)" : 'ok';

    # 3. build
    my $brc = 0;
    $brc = sh( $plog, "cd $qdir && $MAKE clean" )
      if length $BUILDTGT && $BUILDTGT ne 'build';
    $brc ||= sh( $plog, "cd $qdir && $ENVM$MAKE $BUILDTGT" );
    $r->{build} = $brc ? "FAIL($brc)" : 'ok';

    # 4. tests
    if ($TESTS) {
        my $no_test = show_var( $dir, 'NO_TEST' );
        if ( $no_test eq 'Yes' ) {
            $r->{test} = 'skip (NO_TEST)';
        }
        else {
            my $trc = sh( $plog, "cd $qdir && $ENVM$MAKE test" );
            $r->{test} = $trc ? "FAIL($trc)" : 'ok';
        }
    }
    $result{$p} = $r;
    logmsg(
        sprintf(
            "   manifests=%s deps=%s build=%s test=%s",
            $r->{manifests}, $r->{deps}, $r->{build}, $r->{test}
        )
    );
}

# summary
{
    open( my $fh, '>', $SUMMARY ) or die "open $SUMMARY: $!";
    print {$fh} "port\tmanifests\tdeps\tbuild\ttest\n"
      or die "write $SUMMARY: $!";
    for my $p ( sort keys %result ) {
        my $r = $result{$p};
        print {$fh}
          join( "\t", $p, $r->{manifests}, $r->{deps}, $r->{build},
            $r->{test} ), "\n"
          or die "write $SUMMARY: $!";
    }
    close $fh or die "close file: $!";
}
logmsg("summary: $SUMMARY");
my @failed = grep {
         $result{$_}{manifests} =~ /^FAIL/
      || $result{$_}{deps} =~ /^FAIL/
      || $result{$_}{build} ne 'ok'
      || $result{$_}{test} =~ /^FAIL/
} sort keys %result;
logmsg( "ports with failures: " . ( @failed ? join( ' ', @failed ) : 'none' ) );
close STDOUT or die "close stdout: $!";
exit( @failed ? 1 : 0 );
