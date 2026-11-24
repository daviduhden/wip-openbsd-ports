#!/usr/bin/env perl
#
# Verify and package selected ports. Use --regenerate to refresh checked
# source inputs or --update-plist to update packing lists.

use strict;
use warnings;
use Getopt::Long   qw(GetOptions);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use FindBin        qw($RealBin);
use lib $RealBin;
use PortTools qw(inventory capture_command shell_quote dependency_specs
  dependency_path package_name generated_files packing_lists prepare_manifests);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX      qw(strftime);

my $self = File::Spec->rel2abs($0);
my $WIP  = dirname( dirname($self) );    # <collection>/tools/<script>
my $PORTS;
my $LOGDIR;
my $PKGADD     = '';
my $MAKE       = 'make';
my $JOBS       = 1;
my $ALL        = 0;
my $TESTS      = 1;
my $BUILD      = 'package';
my $REGENERATE = 0;
my $PLIST      = 0;
my $ONLY       = '';
my $DRYRUN     = 0;

GetOptions(
    'ports=s'      => \$PORTS,
    'wip=s'        => \$WIP,
    'logdir=s'     => \$LOGDIR,
    'pkg-add=s'    => \$PKGADD,
    'make=s'       => \$MAKE,
    'jobs=i'       => \$JOBS,
    'all'          => \$ALL,
    'regenerate'   => \$REGENERATE,
    'update-plist' => \$PLIST,
    'only=s'       => \$ONLY,
    'tests!'       => \$TESTS,
    'build=s'      => \$BUILD,
    'dry-run'      => \$DRYRUN,
    'help'         => sub { usage(0); },
) or usage(2);

die "--jobs must be a positive integer\n" if $JOBS <= 0;
die "--ports must name an explicit disposable OpenBSD tree\n"
  if !$DRYRUN && !defined $PORTS;
die "--build must be a single make target\n" if $BUILD !~ /\A[a-zA-Z][\w-]*\z/;
$PORTS //= $WIP;
$PORTS = File::Spec->rel2abs($PORTS);
my $native_tree = -d "$PORTS/infrastructure" && -f "$PORTS/Makefile";
die "--ports must name a complete OpenBSD ports tree\n"
  if !$DRYRUN && !$native_tree;
die
  "select an overlay port with --only, or use --all for the overlay inventory\n"
  if $native_tree && !$ONLY && !$ALL;
$LOGDIR //=
  tempdir( 'wip-finish-' . strftime( '%Y%m%d-%H%M%S', localtime ) . '-XXXXXX',
    DIR => '/tmp' );
make_path($LOGDIR) unless -d $LOGDIR;
my $MASTER  = "$LOGDIR/finish.log";
my $SUMMARY = "$LOGDIR/summary.txt";
my $helper  = "$RealBin/../fetch-ports.ksh";
my $ENVM    = $JOBS > 1 ? "MAKE_JOBS=$JOBS " : "";

sub usage {
    my ($status) = @_;
    print <<"USAGE" or die "write stdout: $!";
gen-manifests-and-test.pl - verify, package and test selected ports

  --ports DIR      explicitly selected disposable OpenBSD ports tree
  --wip DIR        overlay inventory when building in a native checkout
  --logdir DIR     log directory (default: /tmp/wip-finish-<timestamp>-<random>)
  --pkg-add CMD    command for dependencies outside the collection
                   (default: let ports resolve dependencies)
  --jobs N         pass MAKE_JOBS=N to make (default: 1)
  --all            process all ports in the overlay inventory
  --regenerate     regenerate dependency manifests and distinfo
  --update-plist   run fake and update-plist before packaging
  --only CAT/PORT  process only this port
  --no-tests       do not run "make test"
  --build TARGET   make target used to build (default: package)
                   native make may install prerequisites
  --dry-run        log the commands without running them
  --help           this message
USAGE
    exit $status;
}

sub logmsg {
    my ($m) = @_;
    my $line = strftime( '%H:%M:%S', localtime ) . " $m\n";
    open( my $fh, '>>', $MASTER ) or die "open $MASTER: $!";
    print {$fh} $line             or die "write $MASTER: $!";
    close $fh                     or die "close $MASTER: $!";
    print $line                   or die "write stdout: $!";
    return;
}

# run a shell command, appending all output to $log; returns the exit code
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

my $inventory_root = $native_tree ? File::Spec->rel2abs($WIP) : $PORTS;
my @ports          = inventory( $helper, $inventory_root );
my %wip            = map { $_ => 1 } @ports;
@ports = grep { $_ eq $ONLY } @ports if $ONLY;
die "no matching installable ports\n" unless @ports;

logmsg("collection: $PORTS");
logmsg("logs:       $LOGDIR");

my %installed;
my @results;
my $capture = sub { $DRYRUN ? ( 0, '' ) : capture_command(@_) };
for my $port (@ports) {
    my $dir       = "$PORTS/$port";
    my @generated = generated_files($dir);
    my @missing =
      grep { !-s "$dir/$_" } ( 'distinfo', @generated, packing_lists($dir) );
    next if !$ALL && !$ONLY && !@missing;
    ( my $label = $port ) =~ s{/}{-}g;
    my $log  = "$LOGDIR/$label.log";
    my $qdir = shell_quote($dir);
    my $run  = sub { sh( $log, "cd $qdir && $_[0]" ) };
    my $step = sub { sh( $log, @_ ) };
    my $r    = {
        gen   => 'blocked',
        deps  => 'blocked',
        build => 'blocked',
        test  => 'skip'
    };
    push @results, [ $port, join( ',', @missing ), $r ];
    logmsg( "=== $port" . ( @missing ? " needs: @missing" : "" ) );

    my %includes = map { $_ => 1 } @generated;
    my $rc =
      prepare_manifests( $step, $dir, $MAKE, \%includes, $REGENERATE, $DRYRUN );
    $r->{gen} = $rc ? "FAIL($rc)" : $DRYRUN ? 'dry-run' : 'ok';
    next if $rc;
    ( $rc, my $specs ) = dependency_specs( $capture, $dir, $MAKE, $TESTS );
    if ( !$rc && $PKGADD ) {
        for my $spec (@$specs) {
            next if $wip{ dependency_path($spec) } || $installed{$spec};
            my ( $name_rc, $pkg ) =
              package_name( $capture, $PORTS, $MAKE, $spec );
            $rc = $name_rc || $step->( "$PKGADD " . shell_quote($pkg) );
            last if $rc;
            $installed{$spec} = 1;
        }
    }
    $r->{deps} = $rc ? "FAIL($rc)" : $DRYRUN ? 'dry-run' : 'ok';
    next if $rc;

    $rc = $PLIST ? $run->("$ENVM$MAKE fake") : 0;
    $rc ||= $run->("$MAKE update-plist") if $PLIST;
    $rc ||= $run->("$ENVM$MAKE $BUILD");
    $r->{build} = $rc ? "FAIL($rc)" : $DRYRUN ? 'dry-run' : 'ok';
    next unless $TESTS && !$rc;
    my ( $query_rc, $no_test ) = $capture->("cd $qdir && $MAKE show=NO_TEST");
    if ($query_rc) {
        $r->{test} = "FAIL($query_rc)";
    }
    elsif ( lc($no_test) ne 'yes' ) {
        my $test_rc = $run->("$ENVM$MAKE test");
        $r->{test} = $test_rc ? "FAIL($test_rc)" : $DRYRUN ? 'dry-run' : 'ok';
    }
}

open my $summary, '>', $SUMMARY or die "open $SUMMARY: $!";
print {$summary} "port\tneeds\tgen\tdeps\tbuild\ttest\n"
  or die "write $SUMMARY: $!";
my @failed;
for my $entry (@results) {
    my ( $port, $needs, $r ) = @$entry;
    my @status = @$r{qw(gen deps build test)};
    print {$summary} join( "\t", $port, $needs, @status ), "\n"
      or die "write $SUMMARY: $!";
    logmsg(
        "$port gen=$r->{gen} deps=$r->{deps} build=$r->{build} test=$r->{test}"
    );
    push @failed, $port if grep { /^(?:FAIL|blocked)/ } @status;
}
close $summary or die "close $SUMMARY: $!";
logmsg("summary: $SUMMARY");
logmsg( "ports with failures: " . ( @failed ? join( ' ', @failed ) : 'none' ) );
close STDOUT or die "close stdout: $!";
exit( @failed ? 1 : 0 );
