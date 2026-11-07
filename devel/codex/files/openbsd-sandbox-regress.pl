#!/usr/bin/perl
# Run after rebuilding/installing Codex on OpenBSD; no model or API required.
# Usage: perl openbsd-sandbox-regress.pl [--quick] [/absolute/path/to/codex]
# --quick is retained for compatibility; all rejection checks always run.
# Verify fail-closed rejection; this does not test supported OS isolation.

use strict;
use warnings;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Temp   qw(tempdir tempfile);
use Getopt::Long qw(GetOptions);
use POSIX       qw(WNOHANG setpgid _exit);
use Time::HiRes qw(time sleep);
use constant {
    COMMAND_TIMEOUT   => 120,
    SETUP_FAILURE     => 125,
    SANDBOX_UNAVAILABLE => 77,
    SIGNAL_EXIT_BASE  => 128,
    TERMINATION_GRACE => 0.2,
    POLL_INTERVAL     => 0.05,
};

sub write_file {
    my ( $path, $contents ) = @_;
    open my $fh, '>', $path or die "open $path: $!\n";
    print {$fh} $contents or die "write $path: $!\n";
    close $fh             or die "close $path: $!\n";
    return;
}

sub read_file {
    my ($path) = @_;
    return undef unless -e $path;
    open my $fh, '<', $path or die "open $path: $!\n";
    binmode $fh;
    local $/ = undef;
    my $contents = <$fh>;
    close $fh or die "close $path: $!\n";
    return defined $contents ? $contents : '';
}

sub find_executable {
    my ($name) = @_;
    my @paths =
      $name =~ m{/}
      ? ($name)
      : map { File::Spec->catfile( length($_) ? $_ : '.', $name ) }
      split /:/, ( $ENV{PATH} // '' ), -1;
    for my $path (@paths) {
        return abs_path($path) if -f $path && -x $path;
    }
    die "Executable not found: $name\n";
}

# Capture to regular files so a noisy compiler cannot fill a pipe and deadlock.
# Give each command its own process group so timeouts also stop descendants.
sub capture {
    my ( $base, $work, $args, $timeout ) = @_;
    $timeout //= COMMAND_TIMEOUT;
    my ( $out, $out_path ) =
      tempfile( 'stdout-XXXXXX', DIR => $base, UNLINK => 1 );
    my ( $err, $err_path ) =
      tempfile( 'stderr-XXXXXX', DIR => $base, UNLINK => 1 );
    my $pid = fork;
    die "fork: $!\n" unless defined $pid;
    if ( !$pid ) {
        my $started = eval {

            # Capture setup diagnostics too, before cwd/process-group changes.
            open STDERR, '>&', $err or die "redirect stderr: $!\n";
            open STDOUT, '>&', $out or die "redirect stdout: $!\n";
            setpgid( 0, 0 ) == 0 or die "setpgid: $!\n";
            chdir $work          or die "chdir $work: $!\n";

            # The wrapper is outside the sandbox. Codex and every target inherit
            # the core limit; argv is forwarded without shell interpolation.
            exec '/bin/sh', '-c', 'ulimit -c 0 || exit 125; exec "$@"',
              'codex-regression', @$args;
            die "exec: $!\n";
        };
        if ( !$started ) {
            print {*STDERR} $@ or _exit(SETUP_FAILURE);
        }
        _exit(SETUP_FAILURE);
    }
    my $close_error = '';
    close $out or $close_error = "close capture stdout: $!\n";
    close $err or $close_error .= "close capture stderr: $!\n";
    my $deadline = time + $timeout;
    my ( $status, $timed_out );
    while (1) {
        my $waited = waitpid( $pid, WNOHANG );
        if ( $waited == $pid ) {
            $status = $?;
            last;
        }
        next                if $waited == -1 && $!{EINTR};
        die "waitpid: $!\n" if $waited == -1;
        if ( time >= $deadline ) {

            # Also signal the PID in case startup has not yet created the group.
            kill 'TERM', -$pid;
            kill 'TERM', $pid;
            sleep TERMINATION_GRACE;
            kill 'KILL', -$pid;
            kill 'KILL', $pid;
            my $reaped;
            do { $reaped = waitpid( $pid, 0 ); }
              while $reaped == -1 && $!{EINTR};
            $reaped == $pid or die "waitpid after timeout: $!\n";
            $status    = $?;
            $timed_out = 1;
            last;
        }
        sleep POLL_INTERVAL;
    }
    die $close_error if length $close_error;
    my $signal = $status & 127;
    my $exit   = $signal ? SIGNAL_EXIT_BASE + $signal : $status >> 8;
    return ( $exit, $timed_out, read_file($out_path) . read_file($err_path) );
}

# A refusal must name the missing backend and leave the child marker absent.
# Startup failures, signals and timeouts never demonstrate policy rejection.
sub managed_rejection_passed {
    my ( $exit, $timed_out, $output, $marker_exists ) = @_;
    return !$timed_out
      && !$marker_exists
      && $exit > 0
      && $exit < SIGNAL_EXIT_BASE
      && $exit != SETUP_FAILURE
      && $exit != 126
      && $exit != 127
      && index( $output, 'OpenBSD has no supported command sandbox' ) >= 0;
}

sub main {
    die
      "Run this regression suite on OpenBSD after installing the new package\n"
      unless $^O eq 'openbsd';
    my $quick = 0;
    my $usage = "Usage: $0 [--quick] [/absolute/path/to/codex]\n";
    GetOptions( 'quick' => \$quick ) or die $usage;
    die $usage if @ARGV > 1;
    my $codex = find_executable( $ARGV[0] // 'codex' );
    my $perl  = find_executable($^X);
    my $probe_source = File::Spec->catfile(
        dirname( abs_path($0) ), 'openbsd-sandbox-probe.pl'
    );
    die "Probe not found: $probe_source\n" unless -f $probe_source;
    my $base =
      tempdir( 'codex-openbsd-regress-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    $base = abs_path($base);
    my $work = "$base/workspace";
    mkdir $work or die "mkdir $work: $!\n";
    my $probe = "$work/sandbox-probe.pl";
    write_file( $probe, read_file($probe_source) );
    chmod 0644, $probe or die "chmod $probe: $!\n";
    mkdir "$base/home" or die "mkdir $base/home: $!\n";
    local $ENV{CODEX_HOME} = "$base/home";
    write_file( "$base/home/config.toml",
            "[permissions.openbsd-read]\nextends=\":read-only\"\n"
          . "[permissions.openbsd-read.network]\nenabled=true\n"
          . "[permissions.openbsd-workspace]\nextends=\":workspace\"\n"
          . "[permissions.openbsd-workspace.network]\nenabled=true\n" );
    my @failures;
    for my $mode ( ':read-only', ':workspace',
        'openbsd-read', 'openbsd-workspace' )
    {
        my $marker = "$work/rejected-" . scalar(@failures) . "-$mode";
        my $ok = eval {
            my @args = (
                $codex, 'sandbox', '--permission-profile', $mode, '--',
                $perl, $probe, 'write', $marker
            );
            my ( $exit, $timed_out, $output ) = capture( $base, $work, \@args );
            my $passed = managed_rejection_passed(
                $exit, $timed_out, $output, -e $marker || -l $marker
            );
            print( ( $passed ? 'PASS' : 'FAIL' )
                  . " $mode rejected before execution (exit $exit)\n" )
              or die "write stdout: $!\n";
            print $output if !$passed;
            $passed;
        };
        print "FAIL $mode: $@" if $@;
        push @failures, $mode unless $ok;
    }

    # Execute the identical child in explicitly unrestricted mode. This checks
    # that absent markers above are not merely a broken probe or executable.
    my $marker = "$work/full-access-marker";
    my $control_ok = eval {
        my @args = (
            $codex, 'sandbox', '--permission-profile', ':danger-full-access',
            '--', $perl, $probe, 'write', $marker
        );
        my ( $exit, $timed_out, $output ) = capture( $base, $work, \@args );
        my $contents = read_file($marker);
        my $passed = !$timed_out && $exit == 0
          && defined($contents) && $contents eq 'changed';
        print( ( $passed ? 'PASS' : 'FAIL' )
              . " explicit full-access control (exit $exit)\n" )
          or die "write stdout: $!\n";
        print $output if !$passed;
        $passed;
    };
    print "FAIL full-access control: $@" if $@;
    push @failures, 'full-access control' unless $control_ok;
    if (@failures) {
        print {*STDERR} scalar(@failures)
          . ' failed: ' . join( ', ', @failures ) . "\n"
          or die "write stderr: $!\n";
        return 1;
    }
    print {*STDERR}
      "UNSUPPORTED: OpenBSD command sandbox unavailable; rejection checks passed\n"
      or die "write stderr: $!\n";
    return SANDBOX_UNAVAILABLE;
}

exit main() unless caller;
1;
