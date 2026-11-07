use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Copy qw(copy);
use Cwd qw(abs_path);
my $repo = abs_path('.');
my $fixture = tempdir(CLEANUP => 1);
make_path("$fixture/.git");
copy("$repo/fetch-ports.ksh", "$fixture/fetch-ports.ksh") or die $!;
sub makefile($path, $contents) {
    make_path("$fixture/$path");
    open my $file, '>', "$fixture/$path/Makefile" or die $!;
    print {$file} $contents or die $!;
    close $file or die $!;
}
makefile('devel/demo', ".include <bsd.port.mk>\n");
makefile('sysutils/group', ".include <bsd.port.subdir.mk>\n");
makefile('sysutils/group/child', ".include <bsd.port.mk>\n");
for my $support (qw(audit logs tools scripts tests docs infrastructure)) {
    makefile("$support/extracted", "all:\n");
    makefile("$support/sources/extracted", "all:\n");
}
local $ENV{WIP_OPENBSD_PORTS_DIR} = $fixture;
open my $pipe, '-|', 'ksh', "$fixture/fetch-ports.ksh", '--list' or die $!;
my @ports = <$pipe>;
ok(close($pipe), 'inventory completes without provisioning');
chomp @ports;
is_deeply(\@ports, ['devel/demo', 'sysutils/group/child'],
    'inventory includes ports and nested children, excludes support sources');
done_testing;
