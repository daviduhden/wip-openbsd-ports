#!/usr/bin/env perl
#
# gen-manifests-and-test.pl - regenerate the missing generated manifests and
# build/test the ports that still need it.
#
# For every port whose distinfo, pkg/PLIST or module manifest (*.inc) is missing
# or empty (0 bytes) the script
#   1. regenerates them: 'make makesum', 'make update-plist' for a missing
#      PLIST, and the module manifest (modules.inc, crates.inc or cabal.inc),
#   2. installs the dependencies outside this collection with 'pkg_add -Dsnap',
#   3. builds the port ('make install') and runs its tests ('make test') unless
#      the port sets NO_TEST.
#
# Logs are written under /tmp.  Nothing is pushed anywhere.
#
# Usage: gen-manifests-and-test.pl [--ports DIR] [--logdir DIR] [--pkg-add CMD]
#                                  [--jobs N] [--all] [--only cat/port]
#                                  [--no-tests] [--build TARGET] [--dry-run]
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

my $self  = File::Spec->rel2abs($0);
my $PORTS = dirname( dirname($self) );    # <collection>/tools/<script>
my $LOGDIR;
my $PKGADD = 'pkg_add -Dsnap';
my $MAKE   = 'make';
my $JOBS   = 1;
my $ALL    = 0;
my $TESTS  = 1;
my $BUILD  = 'install';
my $ONLY   = '';
my $DRYRUN = 0;

GetOptions(
    'ports=s'   => \$PORTS,
    'logdir=s'  => \$LOGDIR,
    'pkg-add=s' => \$PKGADD,
    'make=s'    => \$MAKE,
    'jobs=i'    => \$JOBS,
    'all'       => \$ALL,
    'only=s'    => \$ONLY,
    'tests!'    => \$TESTS,
    'build=s'   => \$BUILD,
    'dry-run'   => \$DRYRUN,
    'help'      => sub { usage(0); },
) or usage(2);

die "--jobs must be a positive integer\n" if $JOBS <= 0;
$PORTS = File::Spec->rel2abs($PORTS);
$LOGDIR //=
  tempdir( 'wip-finish-' . strftime( '%Y%m%d-%H%M%S', localtime ) . '-XXXXXX',
    DIR => '/tmp' );
make_path($LOGDIR) unless -d $LOGDIR;
my $MASTER  = "$LOGDIR/finish.log";
my $SUMMARY = "$LOGDIR/summary.txt";
my $ENVM    = $JOBS > 1 ? "MAKE_JOBS=$JOBS " : "";

sub usage {
    my ($status) = @_;
    print <<"USAGE" or die "write stdout: $!";
gen-manifests-and-test.pl - regenerate missing manifests, build and test ports

  --ports DIR      port collection (default: parent of this script's dir)
  --logdir DIR     log directory (default: /tmp/wip-finish-<timestamp>-<random>)
  --pkg-add CMD    command for dependencies outside the collection
                   (default: "pkg_add -Dsnap")
  --jobs N         pass MAKE_JOBS=N to make (default: 1)
  --all            process every port, not only the ones with missing manifests
  --only CAT/PORT  process only this port
  --no-tests       do not run "make test"
  --build TARGET   make target used to build (default: install)
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

# <collection>/<cat>/<port> -> <logdir>/<cat>-<port>.log
sub portlog {
    my ($p) = @_;
    ( my $n = $p ) =~ s{/}{-}g;
    return "$LOGDIR/$n.log";
}

sub find_ports {
    my @ports;
    opendir( my $dh, $PORTS ) or die "$PORTS: $!";
    for my $cat ( sort readdir $dh ) {
        next if $cat =~ /^\./;
        next
          if $cat eq 'logs'
          || $cat eq 'tools'
          || $cat eq 'audit'
          || $cat eq 'infrastructure';
        my $catdir = File::Spec->catdir( $PORTS, $cat );
        next unless -d $catdir;
        find(
            {
                wanted => sub {
                    return unless basename($_) eq 'Makefile';
                    return if $File::Find::name =~ m{/(CVS|files|patches)/};
                    my $rel = File::Spec->abs2rel( $File::Find::name, $PORTS );
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

sub manifest_state {
    my ($f) = @_;
    return 'missing' unless -e $f;
    return 'empty'   unless -s $f;
    return 'ok';
}

# a manifest label maps to the file it stands for
sub labelpath {
    my ( $dir, $label ) = @_;
    return "$dir/pkg/PLIST" if $label eq 'PLIST';
    return "$dir/$label";
}

# expected module manifests for a port, from its Makefile
sub manifests {
    my ($dir) = @_;
    open( my $fh, '<', "$dir/Makefile" ) or return ();
    my $t = do { local $/ = undef; <$fh> // q{} };
    close $fh or die "close file: $!";
    return () if $t =~ /bsd\.port\.subdir\.mk/;    # SUBDIR helper, not a port
    my %inc;
    while ( $t =~ /\.include\s+"([A-Za-z0-9_.-]+\.inc)"/g ) {
        $inc{$1} = 1;
    }
    $inc{'modules.inc'} = 1 if $t =~ /^MODGO_MODNAME/m;
    $inc{'crates.inc'}  = 1
      if $t =~ /^MODULES\s*=.*\bcargo\b/m
      || $t =~ /^CONFIGURE_STYLE\s*=\s*cargo/m;
    $inc{'cabal.inc'} = 1 if $t =~ /^MODULES\s*=.*\bcabal\b/m;
    return sort keys %inc;
}

# dependencies of a port as port paths (cat/port), from the framework
sub port_deps {
    my ($dir) = @_;
    my $qdir = shell_quote($dir);
    my %deps;
    for my $var (qw(BUILD_DEPENDS LIB_DEPENDS RUN_DEPENDS TEST_DEPENDS)) {
        my $val = cap("cd $qdir && $MAKE show=$var");
        for my $tok ( split /\s+/, $val ) {
            $deps{$1} = 1 if $tok =~ m{^([A-Za-z0-9_.+-]+/[A-Za-z0-9_.+-]+)};
        }
    }
    return sort keys %deps;
}

# ports whose generated manifests are missing or empty, plus what is missing
sub pending_ports {
    my (@ports) = @_;
    my @pending;
    for my $p (@ports) {
        my $dir = "$PORTS/$p";
        my @missing;
        my $d = manifest_state("$dir/distinfo");
        push @missing, 'distinfo' if $d ne 'ok';
        my $pl = manifest_state("$dir/pkg/PLIST");
        push @missing, 'PLIST' if $pl ne 'ok';
        for my $i ( manifests($dir) ) {
            push @missing, $i if manifest_state("$dir/$i") ne 'ok';
        }
        push @pending, [ $p, @missing ] if @missing;
    }
    return @pending;
}

# ---------------------------------------------------------------- main

logmsg("collection: $PORTS");
logmsg("logs:       $LOGDIR");

my @ports = find_ports();
die "no ports found under $PORTS\n" unless @ports;
my %wip = map { $_ => 1 } @ports;
@ports = grep { $_ eq $ONLY } @ports if length $ONLY;

my @todo;
if ($ALL) {
    @todo = map { [ $_, () ] } @ports;
}
else {
    @todo = pending_ports(@ports);
}
logmsg( "ports to process: "
      . scalar(@todo)
      . ( $ALL ? ' (--all)' : ' (missing manifests)' ) );

my ( %installed, %result );
for my $item (@todo) {
    my ( $p, @missing ) = @$item;
    my $dir  = "$PORTS/$p";
    my $plog = portlog($p);
    my $qdir = shell_quote($dir);
    logmsg( "=== $p" . ( @missing ? "  needs: @missing" : "" ) );
    my $r = { gen => '-', deps => '-', build => '-', test => 'skip' };

    # 1. regenerate the missing manifests
    my $grc = 0;
    $grc |= sh( $plog, "cd $qdir && $MAKE makesum" )
      if grep { $_ eq 'distinfo' } @missing;
    $grc |= sh( $plog, "cd $qdir && $MAKE update-plist" )
      if grep { $_ eq 'PLIST' } @missing;
    $grc |= sh( $plog, "cd $qdir && $MAKE modgo-gen-modules > modules.inc" )
      if grep { $_ eq 'modules.inc' } @missing;
    $grc |= sh( $plog,
"cd $qdir && { $MAKE modcargo-gen-crates-licenses || $MAKE modcargo-gen-crates; } > crates.inc"
    ) if grep { $_ eq 'crates.inc' } @missing;
    $grc |= sh( $plog, "cd $qdir && $MAKE cabal-inc" )
      if grep { $_ eq 'cabal.inc' } @missing;
    $r->{needs} = join( ',', @missing );
    $r->{gen} =
        $grc    ? "FAIL($grc)"
      : $DRYRUN ? 'dry-run'
      : ( grep { manifest_state( labelpath( $dir, $_ ) ) ne 'ok' } @missing )
      ? 'FAIL(empty)'
      : 'ok';

    # 2. dependencies outside the collection
    my $drc = 0;
    for my $dep ( port_deps($dir) ) {
        next if $wip{$dep};
        next unless -d "$PORTS/$dep";
        next if $installed{$dep};
        my $qdep = shell_quote("$PORTS/$dep");
        my $pkg  = cap("cd $qdep && $MAKE show=PKGNAME");
        next unless length $pkg;
        my $qpkg   = shell_quote($pkg);
        my $dep_rc = sh( $plog, "cd $qdep && $PKGADD $qpkg" );
        $drc |= $dep_rc;
        $installed{$dep} = 1 unless $dep_rc;
    }
    $r->{deps} = $drc ? "FAIL($drc)" : 'ok';

    # 3. build and test
    my $brc = sh( $plog, "cd $qdir && $MAKE clean && $ENVM$MAKE $BUILD" );
    $r->{build} = $brc ? "FAIL($brc)" : 'ok';
    if ($TESTS) {
        my $no_test = cap("cd $qdir && $MAKE show=NO_TEST");
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
            "   gen=%s deps=%s build=%s test=%s",
            $r->{gen}, $r->{deps}, $r->{build}, $r->{test}
        )
    );
}

{
    open( my $fh, '>', $SUMMARY ) or die "open $SUMMARY: $!";
    print {$fh} "port\tneeds\tgen\tdeps\tbuild\ttest\n"
      or die "write $SUMMARY: $!";
    for my $p ( sort keys %result ) {
        my $r = $result{$p};
        print {$fh} join( "\t",
            $p, $r->{needs}, $r->{gen}, $r->{deps}, $r->{build}, $r->{test} ),
          "\n"
          or die "write $SUMMARY: $!";
    }
    close $fh or die "close file: $!";
}
logmsg("summary: $SUMMARY");
my @failed = $DRYRUN ? () : grep {
         $result{$_}{gen}   =~ /^FAIL/
      || $result{$_}{deps}  =~ /^FAIL/
      || $result{$_}{build} !~ /^(?:ok|dry-run)$/
      || $result{$_}{test}  =~ /^FAIL/
} sort keys %result;
logmsg( "ports with failures: " . ( @failed ? join( ' ', @failed ) : 'none' ) );
close STDOUT or die "close stdout: $!";
exit( @failed ? 1 : 0 );
