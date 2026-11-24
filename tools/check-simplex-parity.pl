#!/usr/bin/env perl

use v5.36;
use Digest::SHA  qw(sha256_hex);
use File::Glob   qw(bsd_glob);
use FindBin      qw($Bin);
use Getopt::Long qw(GetOptions);

my ( $ghc, $cabal, $index_state );
GetOptions(
    'ghc-version=s'   => \$ghc,
    'cabal-version=s' => \$cabal,
    'index-state=s'   => \$index_state,
  )
  && !@ARGV
  or die "Usage: $0 [--ghc-version V --cabal-version V --index-state STATE]\n";
my @provenance = grep { defined } ( $ghc, $cabal, $index_state );
die "provide all three provenance values, each on one line\n"
  if @provenance
  && ( @provenance != 3 || grep { /[^[:print:]]/ || !length } @provenance );

my $chat   = "$Bin/../net/simplex-chat";
my $mq     = "$Bin/../net/simplexmq";
my $failed = 0;

sub read_file ($path) {
    open my $fh, '<:raw', $path or die "open $path: $!\n";
    local $/;
    return <$fh> // '';
}

sub compare ( $name, $a, $b ) {
    if ( !defined($a) || !defined($b) || $a ne $b ) {
        say "DIFF\t$name";
        $failed = 1;
    }
    else {
        say "OK\t$name";
    }
}

sub commit_pin ( $makefile, $project ) {
    my @matches;
    while ( $makefile =~
        /^DIST_TUPLE\h*\+=\h*github\h+(\S+)\h+\Q$project\E\h+([\da-f]{40})\h/mg
      )
    {
        push @matches, "$1/$project\@$2";
    }
    return @matches == 1 ? $matches[0] : undef;
}

sub assignment ( $makefile, $name ) {
    my @matches = $makefile =~ /^\Q$name\E\h*=\h*([\da-f.]+)\h*$/mg;
    return @matches == 1 ? $matches[0] : undef;
}

my ( $chat_make, $mq_make ) = map { read_file("$_/Makefile") } ( $chat, $mq );
my ($mq_identity) = $mq_make =~ /^GH_ACCOUNT\h*=\h*([\w-]+)\h*$/m;
my $mq_commit     = assignment( $mq_make, 'GH_COMMIT' );
my $mq_pin        = defined($mq_identity)
  && defined($mq_commit) ? "$mq_identity/simplexmq\@$mq_commit" : undef;
my ( $chat_tuples, $mq_tuples ) =
  map { s/\\\n\h*/ /gr } ( $chat_make, $mq_make );
my $chat_pin = commit_pin( $chat_tuples, 'simplexmq' );
compare( 'simplexmq source pin', $chat_pin, $mq_pin );

for my $dep (qw(aeson direct-sqlcipher hs-socks sqlcipher-simple blst libbbs)) {
    compare(
        "$dep source pin",
        commit_pin( $chat_tuples, $dep ),
        commit_pin( $mq_tuples,   $dep )
    );
}
for my $var (qw(CRYPTOSTORE_V ENTROPY_V HTTP2_V NETWORK_V TLS_V UNIX_TIME_V)) {
    compare(
        $var,
        assignment( $chat_make, $var ),
        assignment( $mq_make,   $var )
    );
}

sub patch_body ($path) {
    return unless -f $path;
    my $body = read_file($path);

    # Retain target, hunk coordinates, context, and edits. The rationale
    # above Index is documentation, independent of what patch applies.
    return $body =~ /^(Index: .*)/ms ? $1 : undef;
}

for my $dep (
    qw(aeson cryptostore direct-sqlcipher entropy http2 network tls unix-time))
{
    my %patches;
    for my $port ( $chat, $mq ) {
        for my $path ( bsd_glob "$port/files/$dep/patch-*" ) {
            my ($file) = $path =~ m{([^/]+)$};
            $patches{$file} = 1;
        }
    }
    if ( !%patches ) {
        say "DIFF\t$dep has no shared patches";
        $failed = 1;
    }
    for my $patch ( sort keys %patches ) {
        compare(
            "$dep/$patch",
            scalar patch_body("$chat/files/$dep/$patch"),
            scalar patch_body("$mq/files/$dep/$patch")
        );
    }
}

sub merge_helper ($path) {
    my $text = read_file($path);

    # Perl::Tidy end-of-block comments are the only accepted divergence.
    return $text =~ s/^(\h*\})\h+\#\# end [^\n]+$/$1/mgr;
}

compare( 'check-package-paths.sh',
    map { read_file("$_/files/check-package-paths.sh") } ( $chat, $mq ) );
compare( 'cabal-deps-merge.pl',
    map { merge_helper("$_/files/cabal-deps-merge.pl") } ( $chat, $mq ) );

if (@provenance) {
    say "GHC\t$ghc";
    say "CABAL_INSTALL\t$cabal";
    say "HACKAGE_INDEX_STATE\t$index_state";
    for my $entry ( [ 'net/simplex-chat', $chat ], [ 'net/simplexmq', $mq ] ) {
        for my $name (qw(Makefile cabal.inc distinfo)) {
            say join "\t", 'SHA256', "$entry->[0]/$name",
              sha256_hex( read_file("$entry->[1]/$name") );
        }
    }
}
exit $failed;
