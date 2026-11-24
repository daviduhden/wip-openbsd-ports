package PortTools;

use strict;
use warnings;
use Exporter   qw(import);
use File::Temp qw(tempfile);
use Fcntl      qw(O_CREAT O_EXCL O_WRONLY);

our @EXPORT_OK = qw(inventory capture_command shell_quote
  dependency_specs dependency_path package_name generated_files
  packing_lists prepare_manifests);

sub inventory {
    my ( $helper, $root ) = @_;
    local $ENV{WIP_OPENBSD_PORTS_DIR} = $root;
    open my $pipe, '-|', 'ksh', $helper, '--list'
      or die "start port inventory: $!";
    my @ports = <$pipe>;
    close $pipe or die "port inventory failed for $root\n";
    chomp @ports;
    return @ports;
}

sub shell_quote {
    my ($text) = @_;
    $text =~ s/'/'"'"'/g;
    return "'$text'";
}

sub capture_command {
    my ($command) = @_;
    open my $pipe, '-|', '/bin/sh', '-c', $command
      or die "capture command: $!";
    my $text = do { local $/; <$pipe> // '' };
    unless ( close $pipe ) {
        my $status = $?;
        return ( $status & 127 ? 128 + ( $status & 127 ) : $status >> 8 || 1,
            '' );
    }
    $text =~ s/\s+\z//;
    return ( 0, $text );
}

sub dependency_path {
    my ($spec) = @_;
    return ( split /,/, $spec, 2 )[0];
}

sub dependency_specs {
    my ( $capture, $dir, $make, $test ) = @_;
    my $qdir = shell_quote($dir);
    my ( $query_rc, $packages ) =
      $capture->("cd $qdir && $make show=MULTI_PACKAGES");
    return ( $query_rc, [] ) if $query_rc;
    my @subpackages = split /\s+/, $packages;
    if ( grep { !/\A-[\w+.-]*\z/ } @subpackages ) {
        warn "invalid MULTI_PACKAGES from $dir: $packages\n";
        return ( 1, [] );
    }
    my @commands =
      ( "$make build-dir-depends", ( $test ? "$make test-dir-depends" : () ) );
    push @commands,
      @subpackages
      ? map { "SUBPACKAGE=$_ $make run-dir-depends" } @subpackages
      : "$make run-dir-depends";
    my %specs;
    for my $command (@commands) {
        my ( $rc, $text ) = $capture->("cd $qdir && $command");
        return ( $rc, [] ) if $rc;
        for my $line ( split /\n/, $text ) {
            my ( $owner, $spec, $extra ) = split /\s+/, $line;
            unless ( defined $spec
                && !defined $extra
                && $spec =~ m{\A[\w+.-]+(?:/[\w+.-]+)+(?:,[\w+.-]*)*\z}
                && dependency_path($spec) !~ m{(?:\A|/)\.{1,2}(?:/|\z)} )
            {
                warn "invalid dependency from $dir: $line\n";
                return ( 1, [] );
            }
            $specs{$spec} = 1 if $owner ne $spec;
        }
    }
    return ( 0, [ sort keys %specs ] );
}

sub package_name {
    my ( $capture,    $root, $make, $spec ) = @_;
    my ( $path,       @parts ) = split /,/, $spec, -1;
    my ( $subpackage, @flavors );
    for my $part (@parts) {
        if ( $part =~ /^-/ ) {
            return ( 1, '' ) if defined $subpackage;
            $subpackage = $part;
        }
        else { push @flavors, $part; }
    }
    my $dir    = shell_quote("$root/$path");
    my $flavor = shell_quote( join ' ', @flavors );
    my $sub    = shell_quote( $subpackage // '' );
    my $assign = '';
    $assign .= "FLAVOR=$flavor "  if @flavors;
    $assign .= "SUBPACKAGE=$sub " if defined $subpackage;
    my $variable = 'FULLPKGNAME' . ( $subpackage // '' );
    my ( $rc, $name ) = $capture->("cd $dir && $assign$make show=$variable");
    return ( 1,   '' ) if !$rc && $name !~ /\A[\w.+-]+\z/;
    return ( $rc, $name );
}

sub makefile_text {
    my ($dir) = @_;
    open my $fh, '<', "$dir/Makefile" or die "open $dir/Makefile: $!";
    my $text = do { local $/; <$fh> // '' };
    close $fh or die "close $dir/Makefile: $!";
    $text =~ s/\\\n/ /g;
    return $text;
}

sub generated_files {
    my ($dir)    = @_;
    my $text     = makefile_text($dir);
    my %includes = map { $_ => 1 }
      $text =~ /^\s*\.s?include\s+"((?:modules|crates|cabal)\.inc)"/mg;
    my @files = sort keys %includes;
    return @files;
}

sub packing_lists {
    my ($dir) = @_;
    my $text = makefile_text($dir);
    my @sub =
      map { /(-[\w+.-]+)/g } $text =~ /^MULTI_PACKAGES\s*[+?]?=([^\n]*)/mg;
    return @sub ? ( map { "pkg/PLIST$_" } @sub ) : 'pkg/PLIST';
}

sub regenerate_include {
    my ( $run, $dir, $name, $command, $dry ) = @_;
    my $dest = "$dir/$name";
    my $qdir = shell_quote($dir);
    return $run->("cd $qdir && $command [temporary output: $name]") if $dry;
    my ( $fh, $temp ) = tempfile( ".$name.XXXXXXXX", DIR => $dir, UNLINK => 1 );
    my $rc = $run->( "cd $qdir && $command", $fh );
    close $fh or die "close $temp: $!";
    if ( !$rc && -s $temp ) {
        my $mode = -s $dest ? ( stat($dest) )[2] & oct("777") : oct("644");
        return 0 if chmod( $mode, $temp ) && rename( $temp, $dest );
        warn "cannot replace $dest: $!\n";
    }
    elsif ( !$rc ) {
        warn "generator produced an empty $dest\n";
    }
    return $rc || 1;
}

sub prepare_manifests {
    my ( $run, $dir, $make, $include, $regenerate, $dry ) = @_;
    my $qdir = shell_quote($dir);
    return $run->("cd $qdir && $make checksum") unless $regenerate;
    my @placeholders;
    my $rc = eval {
        unless ($dry) {
            for my $name ( sort keys %$include ) {
                my $path = "$dir/$name";
                die "refusing to replace symlink $path\n" if -l $path;
                next                                      if -e $path;
                sysopen my $placeholder, $path, O_CREAT | O_EXCL | O_WRONLY,
                  0600
                  or die "create temporary placeholder $path: $!";
                push @placeholders, $path;
                close $placeholder or die "close $path: $!";
            }
        }
        regeneration_steps( $run, $dir, $make, $include, $dry );
    };
    my $err = $@;
    for my $file (@placeholders) {
        next if -s $file;
        unlink $file or warn "cannot remove empty placeholder $file: $!\n";
        $rc ||= 1;
    }
    die $err if $err;
    return $rc;
}

sub regeneration_steps {
    my ( $run, $dir, $make, $include, $dry ) = @_;
    my $qdir = shell_quote($dir);
    my $step = sub { $run->("cd $qdir && $make $_[0]") };

    # Go contributes its generated module lists to the distfiles directly.
    if ( $include->{'modules.inc'} ) {
        my $rc = regenerate_include( $run, $dir, 'modules.inc',
            "$make modgo-gen-modules", $dry );
        return $rc if $rc;
    }

    # Cargo/Cabal need verified extraction of the main source first.
    if ( $include->{'crates.inc'} || $include->{'cabal.inc'} ) {
        my $rc = $step->('makesum');
        return $rc if $rc;
        if ( $include->{'crates.inc'} ) {
            $rc = regenerate_include( $run, $dir, 'crates.inc',
                "$make modcargo-gen-crates", $dry );
            return $rc if $rc;
            $rc = $step->('makesum');
            return $rc if $rc;
            $rc = $step->('configure');
            return $rc if $rc;
            $rc = regenerate_include( $run, $dir, 'crates.inc',
                "$make modcargo-gen-crates-licenses", $dry );
            return $rc if $rc;
        }
        if ( $include->{'cabal.inc'} ) {
            $rc = $step->('cabal-inc');
            return $rc if $rc;
        }
    }
    my $rc = $step->('makesum');
    return $rc || $step->('checksum');
}

1;
