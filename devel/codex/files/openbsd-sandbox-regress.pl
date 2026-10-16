#!/usr/bin/perl
# Run after rebuilding/installing Codex on OpenBSD; no model or API required.
# Usage: perl openbsd-sandbox-regress.pl [/absolute/path/to/codex]
# All writes, including attempted escapes, target disposable fixtures.
# Build cases compile tiny fixtures, never Codex itself. Uses core Perl modules.

use strict;
use warnings;
use Cwd            qw(abs_path);
use File::Basename qw(basename);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use IO::Socket::INET;
use POSIX       qw(WNOHANG setpgid _exit);
use Time::HiRes qw(time sleep);
use constant {
    COMMAND_TIMEOUT   => 120,
    SETUP_FAILURE     => 125,
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

sub main {
    die
      "Run this regression suite on OpenBSD after installing the new package\n"
      unless $^O eq 'openbsd';
    die "Usage: $0 [/absolute/path/to/codex]\n" if @ARGV > 1;
    my $codex = find_executable( $ARGV[0] // 'codex' );
    my $perl  = find_executable($^X);
    my $base =
      tempdir( 'codex-openbsd-regress-XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    $base = abs_path($base);
    my $work = "$base/workspace";
    mkdir $work or die "mkdir $work: $!\n";

    for my $name (qw(.git .agents .codex .aws tmp src)) {
        mkdir "$work/$name" or die "mkdir $work/$name: $!\n";
    }
    mkdir "$base/home" or die "mkdir $base/home: $!\n";
    symlink $base, "$work/escape" or die "symlink: $!\n";
    write_file( "$work/hello.c",     "int main(void) { return 0; }\n" );
    write_file( "$work/src/main.rs", "fn main() {}\n" );
    write_file( "$work/Cargo.toml",
"[package]\nname=\"sandbox-regression\"\nversion=\"0.1.0\"\nedition=\"2021\"\n"
    );
    write_file( "$work/Makefile", "all:\n\t\@echo make-ok\n" );
    local $ENV{CODEX_HOME} = "$base/home";
    local $ENV{CARGO_HOME} = "$work/cargo-home";
    local $ENV{TMPDIR}     = "$work/tmp";
    my @failures;
    my $run = sub {
        my ( $name, $mode, $command, %options ) = @_;

        # Explicit overrides select known policies instead of ambient defaults.
        my @args = (
            $codex,
            'sandbox',
            '-c',
            "sandbox_mode=\"$mode\"",
            '-c',
            'sandbox_workspace_write.exclude_slash_tmp=true',
            '-c',
            'sandbox_workspace_write.exclude_tmpdir_env_var=true',
            '-c',
            'sandbox_workspace_write.network_access='
              . ( $options{network} ? 'true' : 'false' ),
            '--',
            @$command,
        );
        @args = (
            $codex, 'sandbox', '--permission-profile', $mode, '--', @$command
        ) if $options{profile};
        my $before =
          defined $options{unchanged}
          ? read_file( $options{unchanged} )
          : undef;
        my $ok = eval {
            my ( $exit, $timed_out, $output ) = capture( $base, $work, \@args );

            # Setup failures and timeouts are not evidence of enforcement.
            my $passed = !$timed_out
              && (
                $options{denied}
                ? ( $exit != 0
                      && $exit != SETUP_FAILURE
                      && $exit != 126
                      && $exit != 127 )
                : $exit == 0
              );
            if ( defined $options{unchanged} ) {
                my $after = read_file( $options{unchanged} );
                $passed &&= ( defined $before ) == ( defined $after )
                  && ( !defined $before || $before eq $after );
            }
            print( ( $passed ? 'PASS' : 'FAIL' )
                . " $name (exit $exit"
                  . ( $timed_out ? ', timeout' : '' )
                  . ")\n" )
              or die "write stdout: $!\n";
            if ( !$passed ) {
                print $output or die "write stdout: $!\n";
            }
            $passed;
        };
        if ($@) {
            print "FAIL $name: $@" or die "write stdout: $!\n";
        }
        push @failures, $name unless $ok;
    };

    $run->(
        'named read-only profile',
        ':read-only',
        [ '/bin/sh', '-c', 'echo profile-ok' ],
        profile => 1
    );
    $run->(
        'named workspace profile',
        ':workspace',
        [ '/bin/sh', '-c', 'echo profile-ok > profile-output' ],
        profile => 1
    );
    $run->(
        'read-only shell builtin',
        'read-only', [ '/bin/sh', '-c', 'echo shell-ok' ]
    );
    $run->(
        'read-only shell subprocess',
        'read-only', [ '/bin/sh', '-c', '/bin/cat hello.c' ]
    );
    $run->( 'read-only make dry run', 'read-only', [ '/usr/bin/make', '-n' ] );
    $run->(
        'workspace shell pipeline',
        'workspace-write',
        [ '/bin/sh', '-c', 'echo shell-ok | /usr/bin/tee shell-output' ]
    );
    $run->( 'workspace make', 'workspace-write', ['/usr/bin/make'] );

    # Direct Perl probes distinguish real denials from sandboxed shell startup
    # failures. Use the same executable for positive and negative controls.
    my $writer = 'open my $f, ">", $ARGV[0] or die "open: $!\n"; '
      . 'print {$f} "changed" or die "write: $!\n"; close $f or die "close: $!\n";';
    $run->(
        'workspace direct write',
        'workspace-write', [ $perl, '-e', $writer, 'allowed' ]
    );
    $run->(
        'disabled sandbox bypass',
        'danger-full-access', [ $perl, '-e', $writer, "$base/full-access" ]
    );
    my @denials = (
        [ 'read-only write', "$work/readonly-new",   'read-only' ],
        [ 'outside write',   "$base/outside",        'workspace-write' ],
        [ 'symlink escape',  "$work/escape/escaped", 'workspace-write' ],
        map { [ "protected $_", "$work/$_/config", 'workspace-write' ] }
          qw(.git .agents .codex .aws),
    );
    for my $case (@denials) {
        my ( $name, $target, $mode ) = @$case;
        $run->(
            $name, $mode, [ $perl, '-e', $writer, $target ],
            denied    => 1,
            unchanged => $target
        );
    }
    $run->(
        'workspace metadata',
        'workspace-write',
        [
            $perl,
            '-e',
            'chmod 0600, "allowed" or die "chmod: $!\n"; '
              . 'utime undef, undef, "allowed" or die "utime: $!\n";'
        ]
    );
    $run->(
        'same-owner fchown (Cargo SQLite)',
        'workspace-write',
        [
            $perl,
            '-e',
            'open my $f, "+<", "allowed" or die "open: $!\n"; '
              . 'my $gid = (split / /, $))[0]; '
              . 'chown $<, $gid, $f or die "fchown: $!\n"; '
              . 'close $f or die "close: $!\n";'
        ]
    );

    my $listener = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Listen    => 8,
        Proto     => 'tcp',
    ) or die "listen: $!\n";
    my $port = $listener->sockport;
    my $connection =
        'use IO::Socket::INET; my $s = IO::Socket::INET->new('
      . "PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 5) "
      . 'or die "connect: $!\n"; close $s or die "close: $!\n";';
    $run->(
        'network enabled control',
        'workspace-write',
        [ $perl, '-e', $connection ],
        network => 1
    );
    $run->(
        'network disabled',
        'workspace-write',
        [ $perl, '-e', $connection ],
        denied => 1
    );
    close $listener or die "close listener: $!\n";

    $run->(
        'clang compile with authorized TMPDIR',
        'workspace-write', [ '/usr/bin/clang', 'hello.c', '-o', 'hello-c' ]
    );
    $run->(
        'rustc compile',
        'workspace-write',
        [ '/usr/local/bin/rustc', 'src/main.rs', '-o', 'hello-rust' ]
    );
    $run->(
        'cargo offline build',
        'workspace-write', [ '/usr/local/bin/cargo', 'build', '--offline' ]
    );

    for my $tool ( '/usr/bin/clang', '/usr/local/bin/rustc',
        '/usr/local/bin/cargo' )
    {
        $run->(
            basename($tool) . ' read-only startup',
            'read-only', [ $tool, '--version' ]
        );
    }
    if (@failures) {
        print {*STDERR} scalar(@failures)
          . ' failed: '
          . join( ', ', @failures ) . "\n"
          or die "write stderr: $!\n";
        return 1;
    }
    print "All OpenBSD sandbox regressions passed\n"
      or die "write stdout: $!\n";
    close STDOUT or die "close stdout: $!\n";
    return 0;
}

exit main() unless caller;
1;
