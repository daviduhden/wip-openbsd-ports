#!/usr/bin/env perl

use v5.36;
use File::Spec;
use FindBin      qw($Bin);
use Getopt::Long qw(GetOptions);
use lib $Bin;
use PortTools qw(generated_files inventory packing_lists);

my $official;
GetOptions( 'official-tree=s' => \$official )
  or die "Usage: $0 [--official-tree DIR] [PORT ...]\n";
$official = File::Spec->rel2abs($official) if defined $official;

my $root = "$Bin/..";
chdir $root or die "chdir $root: $!\n";

sub read_file ($path) {
    open my $fh, '<', $path or die "open $path: $!\n";
    local $/;
    return <$fh> // '';
}

sub literal_value ( $recipe, $key ) {

    # Only compare single literal assignments. BSD make remains authoritative.
    my @values = $recipe =~ /^\h*\Q$key\E\h*=\h*([\w.+-]+)\h*(?:\#.*)?$/mg;
    return @values == 1 ? $values[0] : undef;
}

sub go_version ($text) {
    return unless defined($text) && $text =~ /\A(\d+)\.(\d+)\.(\d+)\z/;
    return [ $1, $2, $3 ];
}

sub version_cmp ( $a, $b ) {
    return $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2];
}

my @ports = inventory( "$root/fetch-ports.ksh", $root );
die "empty port inventory\n" unless @ports;
my %known = map { $_ => 1 } @ports;
for my $p (@ARGV) {
    die "unknown port: $p\n" unless $known{$p};
}
@ports = @ARGV if @ARGV;

my $official_go;
if ( defined $official ) {
    -f "$official/infrastructure/mk/bsd.port.mk"
      or die "not a ports tree: $official\n";
    $official_go =
      literal_value( read_file("$official/lang/go/Makefile"), 'VERSION' );
}

say join "\t", qw(PORT STATUS ARTIFACT DETAIL);
my $needs_attention = 0;
for my $p (@ports) {
    my $recipe    = read_file("$p/Makefile");
    my $checksums = '';
    my @issues;
    if ( -s "$p/distinfo" ) {
        $checksums = read_file("$p/distinfo");
    }
    elsif ( $recipe !~ /^\h*(?:NO_DISTFILES\h*=\h*Yes|DISTFILES\h*=\h*$)/mi ) {
        push @issues,
          [
            'MISSING', 'distinfo',
            'inspect fetch inputs and run native makesum'
          ];
    }
    else {
        push @issues,
          [ 'REVIEW', 'distinfo', 'recipe may have no distribution files' ];
    }

    my %targets = (
        'crates.inc'  => 'modcargo-gen-crates',
        'modules.inc' => 'modgo-gen-modules',
        'cabal.inc'   => 'cabal-inc',
    );
    for my $inc ( generated_files($p) ) {
        push @issues,
          [ 'MISSING', $inc, "run native make $targets{$inc} then makesum" ]
          unless -s "$p/$inc";
    }

    for my $plist ( packing_lists($p) ) {
        push @issues,
          [
            'REVIEW', $plist,
            'packing list not found; verify native subpackages'
          ]
          unless -s "$p/$plist";
    }

    my $project = literal_value( $recipe, 'GH_PROJECT' );
    my $tag     = literal_value( $recipe, 'GH_TAGNAME' );
    if ( !defined $tag
        && $recipe =~ /^\h*GH_TAGNAME\h*=\h*([\w.+-]*)\$\{V\}\h*$/m )
    {
        my $prefix  = $1;
        my $version = literal_value( $recipe, 'V' );
        $tag = "$prefix$version" if defined $version;
    }

    # Check only the default GitHub archive naming case, where an older
    # related archive is actually listed. Overrides need native inspection.
    if (   defined $project
        && defined $tag
        && $recipe !~
        /^\h*(?:DISTFILES|DISTNAME|EXTRACT_SUFX|GH_COMMIT)\h*[:+?]?=/m )
    {
        $tag =~ s/^(?:[vV]|ver|[Rr]el|[Rr]elease)[-._]?(?=\d)//;
        my @archives =
          $checksums =~ /^SHA256 \((\Q$project\E-[^()]*\.tar\.gz)\)/mg;
        if ( @archives && !grep { $_ eq "$project-$tag.tar.gz" } @archives ) {
            push @issues,
              [
                'REVIEW', 'distinfo',
"archive $project-$tag.tar.gz absent; compare native ALL_DISTFILES"
              ];
        }
    }

    if ( $recipe =~
        /^\h*BUILD_DEPENDS\h*[+?]?=\h*lang\/go>=(\d+\.\d+\.\d+)\h*(?:\#.*)?$/m )
    {
        my $minimum = $1;
        if ( go_version($official_go) ) {
            if ( version_cmp( go_version($official_go), go_version($minimum) ) <
                0 )
            {
                push @issues,
                  [
                    'BLOCKED', 'lang/go',
"selected tree provides $official_go; port requires $minimum"
                  ];
            }
        }
        else {
            push @issues,
              [
                'REVIEW', 'lang/go',
                "verify minimum $minimum in the selected tree"
              ];
        }
    }

    for my $readme ( sort glob "$p/pkg/README*" ) {
        next unless -f $readme && $readme =~ m{/README((?:-[\w.-]+)?)$};
        my $suffix = $1;
        my $plist  = "$p/pkg/PLIST$suffix";
        if ( !-f $plist
            || read_file($plist) !~ m{(?:^|\h)share/doc/pkg-readmes/}m )
        {
            push @issues,
              [
                'REVIEW', "pkg/PLIST$suffix",
                'README entry not found; check native fake and update-plist'
              ];
        }
    }

    if ( !@issues ) {
        say join "\t", $p, 'STATIC_OK', '-', 'native validation pending';
        next;
    }
    for my $issue (@issues) {
        $needs_attention = 1 if $issue->[0] =~ /\A(?:MISSING|BLOCKED)\z/;
        say join "\t", $p, @$issue;
    }
}
exit($needs_attention);
