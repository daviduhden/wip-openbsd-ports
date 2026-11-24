#!/usr/bin/env perl
#
# Verify and package the overlay against an OpenBSD ports checkout.
# Source regeneration, CVS refresh, and installation are opt-in.

use strict;
use warnings;
use Getopt::Long   qw(GetOptions);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use FindBin        qw($RealBin);
use lib $RealBin;
use PortTools qw(inventory capture_command shell_quote dependency_specs
  dependency_path package_name generated_files prepare_manifests);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX      qw(strftime);

my $self = File::Spec->rel2abs($0);
my $WIP  = dirname( dirname($self) );    # <wip>/tools/bulk-build.pl
my $PORTS;
my $CVSROOT = 'anoncvs@anoncvs.ca.openbsd.org:/cvs';
my $LOGDIR;
my $PKG_ADD    = '';
my $MAKE       = 'make';
my $JOBS       = 1;
my $TESTS      = 1;
my $PLIST      = 0;
my $REFRESH    = 0;
my $REGENERATE = 0;
my $SKIPCVS    = 0;
my $BUILDTGT   = 'package';
my $ONLY       = '';
my $DRYRUN     = 0;

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
    'regenerate'    => \$REGENERATE,
    'skip-cvs'      => \$SKIPCVS,
    'build=s'       => \$BUILDTGT,
    'only=s'        => \$ONLY,
    'dry-run'       => \$DRYRUN,
    'help'          => sub { usage(0); },
) or usage(2);

$WIP = File::Spec->rel2abs($WIP);
die "--jobs must be a positive integer\n" if $JOBS <= 0;
die "--ports must name an explicit disposable OpenBSD tree\n"
  if !$DRYRUN && !defined $PORTS;
die "--build must be a single make target\n"
  if $BUILDTGT !~ /\A[a-zA-Z][\w-]*\z/;
$PORTS //= '/usr/ports';
$PORTS = File::Spec->rel2abs($PORTS);
$LOGDIR //=
  tempdir( 'wip-bulk-' . strftime( '%Y%m%d-%H%M%S', localtime ) . '-XXXXXX',
    DIR => '/tmp' );
make_path($LOGDIR) unless -d $LOGDIR;
my $MASTER  = "$LOGDIR/bulk-build.log";
my $SUMMARY = "$LOGDIR/summary.txt";
my $helper  = "$RealBin/../fetch-ports.ksh";
my $ENVM    = $JOBS > 1 ? "MAKE_JOBS=$JOBS " : "";

sub usage {
    my ($status) = @_;
    print <<"USAGE" or die "write stdout: $!";
bulk-build.pl - overlay the wip ports on a clean ports tree and bulk-build them

  --wip DIR         wip ports collection (default: parent of this script's dir)
  --ports DIR       explicitly selected disposable OpenBSD ports tree
  --cvsroot ROOT    CVS root (default: $CVSROOT)
  --logdir DIR      log directory (default: /tmp/wip-bulk-<timestamp>-<random>)
  --pkg-add CMD     command used for dependencies outside the collection
                    (default: let ports resolve dependencies)
  --jobs N          pass MAKE_JOBS=N to make (default: 1)
  --tests           run "make test" when the port has tests (default)
  --no-tests        do not run the port tests
  --update-plist    regenerate an empty pkg/PLIST with "make update-plist"
  --regenerate      refresh dependency metadata and digests (checksums only by default)
  --refresh         explicitly check out or refresh the CVS tree
  --skip-cvs        never touch CVS (use the tree as it is)
  --build TARGET    make target to build the ports (default: package)
                    native make may install prerequisites
  --only CAT/PORT   build only this port
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
    my ( $log, $cmd, $output ) = @_;
    logmsg("run: $cmd");
    return 0 if $DRYRUN;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ( $pid == 0 ) {
        open( STDOUT, '>>', $log )     or die "open $log: $!";
        open( STDERR, '>&', \*STDOUT ) or die "dup: $!";
        print {*STDOUT} "\n=== $cmd\n" or die "write $log: $!";
        if ($output) {
            open STDOUT, '>&', $output or POSIX::_exit(125);
        }
        exec( '/bin/sh', '-c', $cmd ) or POSIX::_exit(127);
    }
    my $waited;
    do { $waited = waitpid( $pid, 0 ); } while $waited == -1 && $!{EINTR};
    die "waitpid: $!" unless $waited == $pid;
    my $status = $?;
    my $rc     = ( $status & 127 ) ? 128 + ( $status & 127 ) : $status >> 8;
    logmsg( sprintf( "  exit %d%s", $rc, $rc ? " (see $log)" : "" ) );
    return $rc;
}

sub ensure_tree {
    return if !$REFRESH || $SKIPCVS || $DRYRUN;
    my $qports   = shell_quote($PORTS);
    my $qcvsroot = shell_quote($CVSROOT);
    if ( !-e $PORTS && !-l $PORTS ) {
        my $script = shell_quote($helper);
        sh( $MASTER, "CVSROOT=$qcvsroot ksh $script --bootstrap $qports" ) == 0
          or die "CVS checkout failed\n";
    }
    else {
        die "cannot refresh a non-CVS or symlinked ports tree: $PORTS\n"
          if -l $PORTS
          || !-d "$PORTS/CVS"
          || !-f "$PORTS/Makefile"
          || !-d "$PORTS/infrastructure";
        sh( $MASTER, "cd $qports && cvs -qd $qcvsroot up -PAd" ) == 0
          or die "CVS update failed\n";
    }
    return;
}

sub sync_ports {
    my (@ports) = @_;
    return if $DRYRUN;
    my $source = shell_quote($WIP);
    my $script = shell_quote($helper);
    my $target = shell_quote($PORTS);
    my $paths  = join ' ', map { shell_quote($_) } @ports;
    sh( $MASTER,
        "WIP_OPENBSD_PORTS_DIR=$source ksh $script --copy-only $target $paths" )
      == 0
      or die "port overlay failed\n";
    return;
}

sub topo_order {
    my ( $deps, @ports ) = @_;
    my %selected = map { $_ => 1 } @ports;
    my ( %state, @order );
    my $visit;
    $visit = sub {
        my ($port) = @_;
        return                            if ( $state{$port} // 0 ) == 2;
        die "dependency cycle at $port\n" if ( $state{$port} // 0 ) == 1;
        $state{$port} = 1;
        for my $dep ( @{ $deps->{$port} } ) {
            my $path = dependency_path($dep);
            $visit->($path) if $path ne $port && $selected{$path};
        }
        $state{$port} = 2;
        push @order, $port;
    };
    $visit->($_) for @ports;
    return @order;
}

logmsg("wip collection: $WIP");
logmsg("ports tree:     $PORTS");
logmsg("logs:           $LOGDIR");

my @all_ports = inventory( $helper, $WIP );
my %wip       = map                 { $_ => 1 } @all_ports;
my @ports     = length $ONLY ? grep { $_ eq $ONLY } @all_ports : @all_ports;
die "no matching installable ports\n" unless @ports;
ensure_tree();
sync_ports(@ports);

my ( %result, %deps, %installed );
my $capture = sub { $DRYRUN ? ( 0, '' ) : capture_command(@_) };
for my $port (@ports) {
    my $dir = $DRYRUN ? "$WIP/$port" : "$PORTS/$port";
    ( my $label = $port ) =~ s{/}{-}g;
    my $log = "$LOGDIR/$label.log";
    my $run = sub { sh( $log, @_ ) };
    my $r   = $result{$port} = {
        manifests => 'blocked',
        deps      => 'blocked',
        build     => 'blocked',
        test      => 'skip',
        log       => $log,
    };
    my %includes = map { $_ => 1 } generated_files($dir);
    my $rc =
      prepare_manifests( $run, $dir, $MAKE, \%includes, $REGENERATE, $DRYRUN );
    $r->{manifests} = $rc ? "FAIL($rc)" : $DRYRUN ? 'dry-run' : 'ok';
    ( $rc, my $specs ) =
      $rc
      ? ( $rc, [] )
      : dependency_specs( $capture, $dir, $MAKE, $TESTS );
    $deps{$port} = $specs;
    next if $r->{manifests} =~ /^FAIL/;
    $r->{deps} = $rc ? "FAIL($rc)" : $DRYRUN ? 'dry-run' : 'ok';
}

for my $port ( topo_order( \%deps, @ports ) ) {
    my $r = $result{$port};
    next if $r->{manifests} =~ /^FAIL/ || $r->{deps} =~ /^FAIL/;
    my $dir    = shell_quote("$PORTS/$port");
    my $run    = sub { sh( $r->{log}, "cd $dir && $_[0]" ) };
    my $dep_rc = 0;
    for my $spec ( @{ $deps{$port} } ) {
        my $path = dependency_path($spec);
        if (   $path ne $port
            && exists $result{$path}
            && $result{$path}{build} !~ /^(?:ok|dry-run)$/ )
        {
            logmsg("blocked $port: prerequisite $spec did not build");
            $r->{deps} = 'blocked';
            last;
        }
        next if !$PKG_ADD || $wip{$path} || $installed{$spec};
        my ( $name_rc, $pkg ) = package_name( $capture, $PORTS, $MAKE, $spec );
        $dep_rc = $name_rc || sh( $r->{log}, "$PKG_ADD " . shell_quote($pkg) );
        last if $dep_rc;
        $installed{$spec} = 1;
    }
    next if $r->{deps} eq 'blocked';
    if ($dep_rc) {
        $r->{deps} = "FAIL($dep_rc)";
        next;
    }
    my $rc = $PLIST ? $run->("$ENVM$MAKE fake") : 0;
    $rc ||= $run->("$MAKE update-plist") if $PLIST;
    $rc ||= $run->("$ENVM$MAKE $BUILDTGT");
    $r->{build} = $rc ? "FAIL($rc)" : $DRYRUN ? 'dry-run' : 'ok';
    next unless $TESTS && !$rc;
    my ( $query_rc, $no_test ) = $capture->("cd $dir && $MAKE show=NO_TEST");
    if ($query_rc) {
        $r->{test} = "FAIL($query_rc)";
    }
    elsif ( lc($no_test) ne 'yes' ) {
        my $test_rc = $run->("$ENVM$MAKE test");
        $r->{test} = $test_rc ? "FAIL($test_rc)" : $DRYRUN ? 'dry-run' : 'ok';
    }
}

open my $summary, '>', $SUMMARY or die "open $SUMMARY: $!";
print {$summary} "port\tmanifests\tdeps\tbuild\ttest\n"
  or die "write $SUMMARY: $!";
my @failed;
for my $port ( sort keys %result ) {
    my $r      = $result{$port};
    my @status = @$r{qw(manifests deps build test)};
    print {$summary} join( "\t", $port, @status ), "\n"
      or die "write $SUMMARY: $!";
    logmsg(
"$port manifests=$r->{manifests} deps=$r->{deps} build=$r->{build} test=$r->{test}"
    );
    push @failed, $port if grep { /^(?:FAIL|blocked)/ } @status;
}
close $summary or die "close $SUMMARY: $!";
logmsg("summary: $SUMMARY");
logmsg( "ports with failures: " . ( @failed ? join( ' ', @failed ) : 'none' ) );
close STDOUT or die "close stdout: $!";
exit( @failed ? 1 : 0 );
