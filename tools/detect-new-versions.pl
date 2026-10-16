#!/usr/bin/env perl
#
# detect-new-versions.pl - report the ports of this collection whose upstream
# release is newer than the version pinned in the port.
#
# The upstream version is taken from the registry that matches how the port
# fetches its source:
#   * Go modules  -> https://proxy.golang.org/<module>/@latest
#   * PyPI        -> https://pypi.org/pypi/<project>/json
#   * GitHub      -> https://api.github.com/repos/<owner>/<repo>/tags
# Ports that fetch from anywhere else are reported as "manual".
#
# Nothing is downloaded or built: only the registry metadata is queried.  The
# report is written both to stdout and to $LOGDIR/report.txt.
#
# Usage: detect-new-versions.pl [--wip DIR] [--logdir DIR] [--only cat/port]
#
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Find qw(find);
use File::Spec;
use POSIX qw(strftime);
use JSON::PP;

my $self   = File::Spec->rel2abs($0);
my $WIP    = dirname(dirname($self));             # <wip>/tools/detect-new-versions.pl
my $LOGDIR = '/tmp/wip-newversions-' . strftime('%Y%m%d-%H%M%S', localtime);
my $ONLY   = '';
my $DRYRUN = 0;
my $UA     = 'wip-newversions/1.0';

GetOptions(
	'wip=s'    => \$WIP,
	'logdir=s' => \$LOGDIR,
	'only=s'   => \$ONLY,
	'dry-run'  => \$DRYRUN,
	'help'     => \&usage,
) or usage();

$WIP = File::Spec->rel2abs($WIP);
make_path($LOGDIR) unless -d $LOGDIR;
my $REPORT = "$LOGDIR/report.txt";
unlink $REPORT;    # start a fresh report for this run

sub usage {
	print <<"USAGE";
detect-new-versions.pl - report ports whose upstream release is newer

  --wip DIR      wip ports collection (default: parent of this script's dir)
  --logdir DIR   log directory (default: /tmp/wip-newversions-<timestamp>)
  --only CAT/PORT  check only this port
  --dry-run      do not query the registries
  --help         this message
USAGE
	exit 0;
}

sub out {
	my ($line) = @_;
	print "$line\n";
	if (open(my $fh, '>>', $REPORT)) { print $fh "$line\n"; close $fh; }
}

# fetch a URL, preferring HTTP::Tiny and falling back to OpenBSD ftp(1) (which
# handles https without IO::Socket::SSL)
sub fetch {
	my ($url) = @_;
	return undef if $DRYRUN;
	my $body;
	if (eval { require HTTP::Tiny; 1 }) {
		my $r = HTTP::Tiny->new(agent => $UA, timeout => 30)->get($url);
		$body = $r->{content} if $r->{success};
	}
	if (!defined $body && -x '/usr/bin/ftp') {
		$body = qx{/usr/bin/ftp -o - -V '$url' 2>/dev/null};
		$body = undef if defined $body && $body eq '';
	}
	if (!defined $body && -x '/usr/bin/curl') {
		$body = qx{/usr/bin/curl -fsSL --max-time 30 '$url' 2>/dev/null};
		$body = undef if defined $body && $body eq '';
	}
	return $body;
}

sub jget {
	my ($url) = @_;
	my $body = fetch($url);
	return undef unless defined $body;
	return eval { decode_json($body) };
}

sub pvar {
	my ($text, $name) = @_;
	return $text =~ /^$name[ \t]*=[ \t]*(.*)$/m ? $1 : undef;
}

sub expand {
	my ($s, $vals) = @_;
	return undef unless defined $s;
	if (defined $vals->{V}) {
		my $vr = $vals->{V};
		$vr =~ s/\.[^.]*$// for (1 .. 2);
		$s =~ s/\$\{V:R:R\}/$vr/g;
	}
	my $prev;
	do {
		$prev = $s;
		$s =~ s/\$\{([A-Za-z0-9_]+)\}/defined $vals->{$1} ? $vals->{$1} : "\${$1}"/ge;
	} while ($s ne $prev);
	return $s;
}

sub esc_mod { my ($p) = @_; $p =~ s/([A-Z])/'!' . lc($1)/ge; return $p; }

sub vnorm { my ($v) = @_; $v =~ s/^[A-Za-z-]*v(?=\d)//; return $v; }

sub vparts { my ($v) = @_; return map { int($_) } ($v =~ /(\d+)/g); }

sub vcmp {
	my ($a, $b) = @_;
	my @x = vparts($a);
	my @y = vparts($b);
	my $n = @x > @y ? scalar(@x) : scalar(@y);
	for my $i (0 .. $n - 1) {
		my $d = ($x[$i] // 0) - ($y[$i] // 0);
		return $d if $d;
	}
	return 0;
}

sub go_latest {
	my ($mod) = @_;
	my $j = jget('https://proxy.golang.org/' . esc_mod($mod) . '/@latest');
	return $j && $j->{Version} ? $j->{Version} : undef;
}

sub pypi_latest {
	my ($name) = @_;
	my $j = jget("https://pypi.org/pypi/$name/json");
	return $j && $j->{info} ? $j->{info}{version} : undef;
}

sub gh_latest {
	my ($acc, $proj, $tagpat) = @_;
	my $j = jget("https://api.github.com/repos/$acc/$proj/tags?per_page=100");
	return undef unless ref $j eq 'ARRAY';
	my $prefix = '';
	if (defined $tagpat) { ($prefix) = $tagpat =~ /^([^0-9]*)/; }
	$prefix = '' unless defined $prefix;
	my @cand;
	for my $t (map { $_->{name} } @$j) {
		next if length $prefix && index($t, $prefix) != 0;
		(my $rest = $t) =~ s/^\Q$prefix\E//;
		next unless $rest =~ /^v?\d+(?:\.\d+)*$/;
		push @cand, $t;
	}
	return undef unless @cand;
	my @sorted = sort { vcmp($a, $b) } @cand;
	return $sorted[-1];
}

sub find_ports {
	my @ports;
	opendir(my $dh, $WIP) or die "$WIP: $!";
	for my $cat (sort readdir $dh) {
		next if $cat =~ /^\./;
		next if $cat eq 'logs' || $cat eq 'tools' || $cat eq 'infrastructure';
		my $catdir = File::Spec->catdir($WIP, $cat);
		next unless -d $catdir;
		find({
			wanted => sub {
				return unless basename($_) eq 'Makefile';
				return if $File::Find::name =~ m{/(CVS|files|patches)/};
				my $rel = File::Spec->abs2rel($File::Find::name, $WIP);
				(my $dir = dirname($rel)) =~ s{^\./}{};
				push @ports, $dir;
			},
			no_chdir => 1,
		}, $catdir);
	}
	closedir $dh;
	return sort @ports;
}

# ---------------------------------------------------------------- main

my @ports = find_ports();
@ports = grep { $_ eq $ONLY } @ports if length $ONLY;
out("# new versions report - " . strftime('%Y-%m-%d %H:%M:%S', localtime));
out("# collection: $WIP");
out("");

my @outdated;
for my $p (@ports) {
	my $mk = File::Spec->catfile($WIP, split(m{/}, $p), 'Makefile');
	open(my $fh, '<', $mk) or next;
	my $text = do { local $/; <$fh> };
	close $fh;

	my %vals;
	$vals{$_} = pvar($text, $_) for qw(V VERSION MODGO_MODNAME MODGO_VERSION MODPY_DISTV GH_ACCOUNT GH_PROJECT GH_TAGNAME);
	$vals{$_} = expand($vals{$_}, \%vals) for keys %vals;

	my ($kind, $cur, $latest);
	if (defined $vals{MODGO_MODNAME} && length $vals{MODGO_MODNAME}) {
		$kind = 'go';
		$cur  = $vals{MODGO_VERSION};
		$latest = go_latest($vals{MODGO_MODNAME});
	} elsif (defined $vals{GH_ACCOUNT} && defined $vals{GH_PROJECT}) {
		$kind = 'gh';
		$cur  = $vals{GH_TAGNAME};
		$latest = gh_latest($vals{GH_ACCOUNT}, $vals{GH_PROJECT}, $vals{GH_TAGNAME});
	} elsif (defined $vals{MODPY_DISTV} && length $vals{MODPY_DISTV}) {
		$kind = 'pypi';
		$cur  = $vals{MODPY_DISTV};
		my $distname = pvar($text, 'DISTNAME') // '';
		my ($name) = $distname =~ /^([A-Za-z0-9_.+-]+?)-?\$\{/;
		$name = $vals{GH_PROJECT} // basename($p) unless defined $name;
		$name =~ s/[-_.]+/-/g;
		$name = lc $name;
		$latest = pypi_latest($name);
	} else {
		$kind = 'manual';
		$cur  = $vals{V} // $vals{VERSION};
	}

	my $status = '??';
	if (defined $latest && defined $cur) {
		my $c = vnorm($cur);
		my $l = vnorm($latest);
		$c =~ s/^[A-Za-z-]*v//;
		$l =~ s/^[A-Za-z-]*v//;
		if ($c eq $l) {
			$status = 'ok';
		} elsif (vcmp($l, $c) > 0) {
			$status = 'OUTDATED';
			push @outdated, [$p, $kind, $cur, $latest];
		} else {
			$status = 'AHEAD';
		}
	}
	out(sprintf("%-9s %-6s %-42s %-18s -> %s",
		$status, $kind, $p, (defined $cur ? $cur : '-'), (defined $latest ? $latest : '-')));
}

out("");
out("outdated: " . (@outdated ? scalar(@outdated) : 0));
out("report: $REPORT");
exit(@outdated ? 1 : 0);
