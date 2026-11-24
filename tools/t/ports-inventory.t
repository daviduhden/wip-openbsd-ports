use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Copy qw(copy);
use Cwd        qw(abs_path);
my $repo    = abs_path('.');
my $fixture = tempdir( CLEANUP => 1 );
make_path("$fixture/.git");
copy( "$repo/fetch-ports.ksh", "$fixture/fetch-ports.ksh" ) or die $!;

sub makefile( $path, $contents ) {
    make_path("$fixture/$path");
    open my $file, '>', "$fixture/$path/Makefile" or die $!;
    print {$file} $contents or die $!;
    close $file             or die $!;
}
makefile( 'devel/demo',           ".include <bsd.port.mk>\n" );
makefile( 'sysutils/group',       ".include <bsd.port.subdir.mk>\n" );
makefile( 'sysutils/group/child', ".include <bsd.port.mk>\n" );
makefile( 'devel/demo/files',     "all:\n" );
makefile( 'devel/demo/patches',   "all:\n" );
for my $support (qw(audit logs tools scripts tests docs infrastructure)) {
    makefile( "$support/extracted",         "all:\n" );
    makefile( "$support/sources/extracted", "all:\n" );
}
local $ENV{WIP_OPENBSD_PORTS_DIR} = $fixture;
open my $pipe, '-|', 'ksh', "$fixture/fetch-ports.ksh", '--list' or die $!;
my @ports = <$pipe>;
ok( close($pipe), 'inventory completes without provisioning' );
chomp @ports;
is_deeply(
    \@ports,
    [ 'devel/demo', 'sysutils/group/child' ],
    'inventory includes ports and nested children, excludes support sources'
);

sub put_file( $path, $contents ) {
    open my $file, '>', $path or die "$path: $!";
    print {$file} $contents or die $!;
    close $file             or die $!;
}

my $target = "$fixture/target";
make_path( "$target/devel/demo/nested/CVS",
    "$target/sysutils", "$target/infrastructure/db" );
put_file( "$target/Makefile",                      "all:\n" );
put_file( "$target/devel/demo/Makefile",           "old port\n" );
put_file( "$target/devel/demo/nested/CVS/Entries", "fixture\n" );
put_file( "$fixture/user.list", "900 _demo\t_demo\tdevel/demo\n" );
put_file(
    "$target/infrastructure/db/user.list",
    "900 _other\t_other\tdevel/other\n"
);
put_file( "$fixture/sysutils/group/Makefile.inc", "CATEGORY = sysutils\n" );

sub copy_ports {
    system 'ksh', "$fixture/fetch-ports.ksh", '--copy-only', $target,
      'devel/demo', 'sysutils/group/child';
}

isnt( copy_ports(), 0, 'account conflict prevents publishing the selection' );
ok( !-e "$target/sysutils/group",
    'group is unchanged after preflight failure' );
open my $old, '<', "$target/devel/demo/Makefile" or die $!;
is( scalar <$old>,
    "old port\n", 'existing port is unchanged after preflight failure' );
close $old or die $!;
put_file(
    "$target/infrastructure/db/user.list",
    "901 _other\t_other\tdevel/other\n"
);
is( copy_ports(), 0, 'overlay publishes the prepared selection' );
ok(
    -f "$target/devel/demo/nested/CVS/Entries",
    'nested CVS metadata is preserved'
);
ok( -f "$target/sysutils/group/Makefile.inc", 'group files are published' );
my @backups = glob "$target/.wip-backups/overlay.*/old/devel/demo/Makefile";
is( scalar @backups, 1, 'displaced port is retained in the transaction' );
ok( !-e "$target/.wip-overlay.lock",
    'successful transaction releases the lock' );

sub contents($path) {
    open my $file, '<', $path or die "$path: $!";
    local $/;
    return scalar <$file> // '';
}

my $registry       = "$target/infrastructure/db/user.list";
my $prior_registry = contents($registry);
my $change_list    = "$target/.wip-changes/devel-demo.created.txt";
my $prior_changes  = contents($change_list);

my $bin = "$fixture/bin";
make_path($bin);
put_file( "$bin/mv", <<'FAIL_MOVE' );
#!/bin/sh
case "$1" in
    */new/sysutils/group/child) exit 1 ;;
esac
exec /bin/mv "$@"
FAIL_MOVE
chmod 0755, "$bin/mv" or die $!;
put_file( "$fixture/devel/demo/Makefile", "new port\n" );
put_file( "$fixture/devel/demo/new-file", "fixture\n" );
put_file( "$fixture/user.list",
    "900 _demo\t_demo\tdevel/demo\n902 _child\t_child\tsysutils/group/child\n"
);
{
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    isnt( copy_ports(), 0, 'publish failure is reported' );
}
open my $restored, '<', "$target/devel/demo/Makefile" or die $!;
is(
    scalar <$restored>,
    ".include <bsd.port.mk>\n",
    'earlier replacement is rolled back after a later failure'
);
close $restored or die $!;
ok( -f "$target/sysutils/group/child/Makefile", 'failed port is restored' );
is( contents($registry),    $prior_registry, 'account registry is restored' );
is( contents($change_list), $prior_changes,  'CVS change list is restored' );
ok( !-e "$target/.wip-overlay.lock", 'successful rollback releases the lock' );

done_testing;
