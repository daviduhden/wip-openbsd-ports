#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Path     qw(make_path remove_tree);
use File::Temp     qw(tempdir);
use POSIX          qw(_exit);

my $root = $ENV{PERL_AUDIT_ROOT} // abs_path( dirname(__FILE__) . '/../..' );
my $tmp  = tempdir( CLEANUP => 1 );
my $sequence = 0;

sub put_file {
    my ( $path, $text ) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh         or die "close $path: $!";
    return;
}

sub get_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    local $/ = undef;
    my $text = <$fh> // '';
    close $fh or die "close $path: $!";
    return $text;
}

sub run_script {
    my ( $script, @args ) = @_;
    my $log = "$tmp/output-" . ++$sequence;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ( !$pid ) {
        open STDOUT, '>',  $log     or _exit(125);
        open STDERR, '>&', \*STDOUT or _exit(125);
        exec {$^X} $^X, "$root/$script", @args or _exit(127);
    }
    my $waited;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "test command timed out\n"; };
        alarm 10;
        $waited = waitpid( $pid, 0 );
        alarm 0;
        1;
    };
    if ( !$ok ) {
        my $error = $@;
        alarm 0;
        kill 'KILL', $pid;
        waitpid( $pid, 0 );
        die $error;
    }
    die "waitpid: $!" unless $waited == $pid;
    my $status = $?;
    return ( $status, get_file($log) );
}

for my $tool (qw(bulk-build gen-manifests-and-test detect-new-versions)) {
    my ( $status, $out ) = run_script( "tools/$tool.pl", '--help' );
    is( $status, 0, "$tool help succeeds" );
    like( $out, qr/Usage|--help/, "$tool help documents options" );
}

my $inc = "$tmp/input.inc";
put_file( $inc,
"MODCABAL_MANIFEST = \\\n\talpha\t1.0\t2\t\\\n\tbeta\t2.0\t0\n\talpha\t1.0\t2\n"
);
my $plan = "$tmp/plan.json";
put_file( $plan,
        '{"install-plan":[{"pkg-name":"alpha","pkg-version":"1.0",'
      . '"pkg-src":{"type":"repo-tar","cabal-file-url":"https://example/revision/9"}},'
      . '{"pkg-name":"gamma","pkg-version":"3.0","pkg-src":{"type":"repo-tar"}}]}'
);
for my $port (qw(simplex-chat simplexmq)) {
    my $script = "net/$port/files/cabal-deps-merge.pl";
    local $ENV{SKIP}  = 'beta';
    local $ENV{EXTRA} = 'delta:4.0:1';
    my ( $status, $out ) = run_script( $script, $inc, $plan );
    is( $status, 0, "$port merges inputs" );
    is(
        $out,
"MODCABAL_MANIFEST\t= \\\n\talpha\t1.0\t2\t\\\n\tdelta\t4.0\t1\t\\\n\tgamma\t3.0\t0\n",
        "$port preserves sorting, deduplication, SKIP and EXTRA precedence"
    );
    my $test_plan = "$tmp/demo.test.plan.json";
    put_file( $test_plan, get_file($plan) );
    my ( $test_status, $test_out ) = run_script( $script, $inc, $test_plan );
    is( $test_status, 0,
        "$port accepts the port Makefile's test.plan.json filename" );
    is( $test_out, $out,
        "$port test plan preserves the same generated manifest" );
    ( $status, $out ) = run_script( $script, "$tmp/absent.inc" );
    isnt( $status, 0, "$port missing input fails" );
    ( $status, $out ) = run_script($script);
    is(
        $out,
        "MODCABAL_MANIFEST\t= \\\n\tdelta\t4.0\t1\n",
        "$port extras without files"
    );
}

my $ports = "$tmp/ports";
make_path("$ports/cat/demo/pkg");
put_file( "$ports/cat/demo/Makefile", "V = 1.0\n" );
for my $tool (qw(bulk-build gen-manifests-and-test detect-new-versions)) {
    my $tree_option = $tool eq 'gen-manifests-and-test' ? '--ports' : '--wip';
    my @args =
      ( $tree_option, $ports, '--logdir', "$tmp/log-$tool", '--dry-run' );
    push @args, '--ports', "$tmp/build-tree", '--skip-cvs'
      if $tool eq 'bulk-build';
    my ( $status, $out ) = run_script( "tools/$tool.pl", @args );
    is( $status, 0, "$tool fixture dry run succeeds without builds/network" );
    like( $out, qr{cat/demo}, "$tool discovers fixture port" );
}

if ( !$ENV{PERL_AUDIT_BASELINE} ) {
    for my $tool (qw(bulk-build gen-manifests-and-test detect-new-versions)) {
        my ( $status, $out ) =
          run_script( "tools/$tool.pl", '--not-a-valid-option' );
        isnt( $status, 0, "$tool rejects unknown options with failure status" );
        like( $out, qr/Unknown option/, "$tool explains invalid input" );
    }
    for my $tool (qw(bulk-build gen-manifests-and-test)) {
        my ( $status, $out ) = run_script( "tools/$tool.pl", '--jobs', '0' );
        isnt( $status, 0, "$tool rejects zero parallelism" );
    }

    my $quoted = "$tmp/ports 'quoted";
    make_path("$quoted/cat/demo/pkg");
    put_file( "$quoted/cat/demo/Makefile",  "V = 1.0\n" );
    put_file( "$quoted/cat/demo/distinfo",  "fixture\n" );
    put_file( "$quoted/cat/demo/pkg/PLIST", "fixture\n" );
    my $make = "$tmp/fake-make";
    put_file(
        $make, "#!$^X\n" . q{
        use strict;
        use warnings;
        if (grep { /^show=/ } @ARGV) { exit 0; }
        print "mock make executed\n";
        exit 0;
    }
    );
    chmod 0700, $make or die "chmod: $!";
    my ( $status, $out ) = run_script( 'tools/gen-manifests-and-test.pl',
        '--ports', $quoted, '--logdir', "$tmp/quoted-logs", '--make', $make,
        '--all' );
    is( $status, 0, 'shell data paths with apostrophes stay literal' );
    like(
        get_file("$tmp/quoted-logs/cat-demo.log"),
        qr/mock make executed/,
        'mock make actually runs inside quoted directory'
    );

    # Inject an offline HTTP client to exercise JSON handling without requests.
    make_path("$tmp/lib/HTTP");
    put_file(
        "$tmp/lib/HTTP/Tiny.pm", q{
        package HTTP::Tiny;
        sub new { my ($class, %options) = @_; die 'TLS not verified' unless $options{verify_SSL}; return bless {}, $class; }
        sub get { return { success => 1, content => $ENV{AUDIT_JSON} }; }
        1;
    }
    );
    local $ENV{PERL5LIB}   = "$tmp/lib";
    local $ENV{AUDIT_JSON} = '[null, 42, {"name":"v2.0"}]';
    put_file( "$ports/cat/demo/Makefile",
        "V = 1.0\nGH_ACCOUNT = example\nGH_PROJECT = demo\nGH_TAGNAME = v1.0\n"
    );
    ( $status, $out ) = run_script( 'tools/detect-new-versions.pl',
        '--wip', $ports, '--logdir', "$tmp/json-logs" );
    is( $status >> 8,
        1, 'valid tag among malformed API entries is still reported outdated' );
    like(
        $out,
        qr/OUTDATED.*cat\/demo.*v2[.]0/,
        'malformed tag entries do not crash registry parsing'
    );

    # The shell itself can die by signal. Shifting $? used to report success.
    ( $status, $out ) = run_script(
        'tools/gen-manifests-and-test.pl', '--ports',
        $quoted,                           '--logdir',
        "$tmp/signal-logs",                '--all',
        '--no-tests',                      '--make',
        'kill -TERM $$; :'
    );
    isnt( $status, 0, 'signal termination is a failed build' );
    like( $out, qr/FAIL[(]143[)]/,
        'signal status is preserved as 128 + SIGTERM' );

    my $failing_make = "$tmp/failing-make";
    put_file(
        $failing_make, "#!$^X\n" . q{
        use strict;
        use warnings;
        exit 3 if grep { $_ eq 'makesum' } @ARGV;
        exit 0;
    }
    );
    chmod 0700, $failing_make or die "chmod: $!";
    ( $status, $out ) = run_script(
        'tools/bulk-build.pl',     '--wip',
        $ports,                    '--ports',
        "$tmp/overlay",            '--logdir',
        "$tmp/manifest-fail-logs", '--skip-cvs',
        '--no-tests',              '--make',
        $failing_make
    );
    isnt( $status, 0, 'failed manifest generation fails the bulk summary' );
    like( $out, qr/manifests=FAIL[(]3[)]/, 'manifest failure is recorded' );

    make_path( "$tmp/bin", "$tmp/cvs-tree/CVS" );
    put_file(
        "$tmp/bin/cvs", "#!$^X\n" . q{
        use strict;
        use warnings;
        use Cwd qw(getcwd);
        open my $f, '>', $ENV{AUDIT_CVS_LOG} or die $!;
        print {$f} getcwd(), "\n", join(' ', @ARGV), "\n" or die $!;
        close $f or die $!;
        exit($ENV{AUDIT_CVS_FAIL} ? 4 : 0);
    }
    );
    chmod 0700, "$tmp/bin/cvs" or die "chmod: $!";
    {
        local $ENV{PATH}          = "$tmp/bin:$ENV{PATH}";
        local $ENV{AUDIT_CVS_LOG} = "$tmp/cvs-call";
        ( $status, $out ) = run_script(
            'tools/bulk-build.pl', '--wip',
            $ports,                '--ports',
            "$tmp/cvs-tree",       '--logdir',
            "$tmp/cvs-logs",       '--no-tests',
            '--make',              $make,
            '--cvsroot',           "root'quoted"
        );
        is( $status, 0, 'mock CVS refresh succeeds' );
        like(
            get_file("$tmp/cvs-call"),
            qr{\A\Q$tmp/cvs-tree\E\n-qd root'quoted up -PAd\n\z},
'CVS runs in the selected tree with the quoted repository root intact'
        );
        local $ENV{AUDIT_CVS_FAIL} = 1;
        ( $status, $out ) = run_script(
            'tools/bulk-build.pl', '--wip',
            $ports,                '--ports',
            "$tmp/cvs-tree",       '--logdir',
            "$tmp/cvs-fail-logs",  '--no-tests',
            '--make',              $make
        );
        isnt( $status, 0, 'failed CVS refresh aborts before overlay/build' );
    }

    my $bad_logs = "$tmp/bad-logs";
    make_path($bad_logs);
    mkdir "$bad_logs/report.txt" or die "mkdir report: $!";
    ( $status, $out ) = run_script( 'tools/detect-new-versions.pl',
        '--wip', $ports, '--logdir', $bad_logs, '--dry-run' );
    isnt( $status, 0, 'unwritable report is not silently ignored' );
    like( $out, qr/unlink|open/, 'report failure reports the operation' );

    my @default_logs;
    for my $run_number ( 1 .. 2 ) {
        ( $status, $out ) = run_script( 'tools/detect-new-versions.pl',
            '--wip', $ports, '--dry-run' );
        is( $status, 0, "default log run $run_number succeeds" );
        my ($directory) = $out =~
          m{report: (/tmp/wip-newversions-[0-9-]+[A-Za-z0-9_]+)/report[.]txt};
        ok( defined $directory,
            "default log run $run_number reports its directory" );
        if ( defined $directory ) {
            is( ( stat($directory) )[2] & 0777,
                0700, 'default log directory is private' );
            push @default_logs, $directory;
        }
    }
    isnt( $default_logs[0], $default_logs[1],
        'repeated runs use distinct default log directories' );
    remove_tree(@default_logs);

    # A two-node substitution cycle used to hang indefinitely.
    put_file( "$ports/cat/demo/Makefile",
        "V = \${VERSION}\nVERSION = \${V}\n" );
    ( $status, $out ) = run_script( 'tools/detect-new-versions.pl',
        '--wip', $ports, '--logdir', "$tmp/cycle-logs", '--dry-run' );
    isnt( $status, 0, 'cyclic make variables fail instead of hanging' );
    like( $out, qr/cyclic.*variable/i, 'cycle failure explains cause' );
}

if ( !$ENV{PERL_AUDIT_BASELINE} ) {
    my $loaded = do "$root/devel/codex/files/openbsd-sandbox-regress.pl";
    die "load sandbox helpers: " . ( $@ || $! ) unless defined $loaded;
    my ( $exit, $timed_out, $output ) =
      capture( $tmp, $tmp,
        [ $^X, '-e', 'print "x" x 100_000; print STDERR "stderr-marker";' ],
        5 );
    is( $exit, 0, 'capture preserves successful exit' );
    ok( !$timed_out, 'successful capture does not time out' );
    is( length($output), 100_013,
        'large stdout and stderr captured without pipe deadlock' );
    ( $exit, $timed_out, $output ) =
      capture( $tmp, $tmp, [ $^X, '-e', 'exit 7;' ], 5 );
    is( $exit, 7, 'capture preserves nonzero exit' );
    ( $exit, $timed_out, $output ) =
      capture( $tmp, "$tmp/missing-cwd", [ '/bin/echo', 'bad' ], 5 );
    is( $exit, 125, 'capture setup errors stay distinct from sandbox denials' );
    like( $output, qr/chdir/, 'capture setup failure includes context' );
    ( $exit, $timed_out, $output ) =
      capture( $tmp, $tmp, [ '/bin/sh', '-c', 'kill -TERM $$' ], 5 );
    is( $exit, 143, 'capture preserves signal termination' );
    ( $exit, $timed_out, $output ) =
      capture( $tmp, $tmp, [ $^X, '-e', 'sleep 5;' ], 0.1 );
    ok( $timed_out, 'capture timeout is explicitly reported' );
    isnt( $exit, 0, 'timed-out target is terminated and reaped' );
}

done_testing();
