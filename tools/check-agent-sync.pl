#!/usr/bin/env perl
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $root = abs_path( dirname(__FILE__) . '/..' );
chdir $root or die "chdir $root: $!\n";
my $base = $ENV{AGENT_SYNC_BASE} // 'HEAD';
my @changed = git_lines('diff', '--name-only', '--diff-filter=ACDMRTUXB', $base, '--');
my %changed = map { $_ => 1 } @changed;
my @untracked = git_lines(qw(ls-files --others --exclude-standard));
for my $path (@untracked) {
    push @changed, $path;
    $changed{$path} = 1;
}
my @instruction_changes = grep {
    m{(?:^|/)AGENTS\.md$} || m{(?:^|/)\.agents/skills/.*/SKILL\.md$}
        || m{(?:^|/)\.github/agents/.*\.agent\.md$}
        || m{(?:^|/)\.github/skills/.*/SKILL\.md$}
        || m{(?:^|/)\.claude/skills/.*/SKILL\.md$}
} @changed;

if (@changed && !@instruction_changes) {
    fail("repository changes detected since $base, but no agent or skill instructions changed");
}
for my $path (@instruction_changes) {
    my @diff = git_lines('diff', '--unified=0', $base, '--', $path);
    my @content = grep { /^[+-][^+-]/ && /\S/ } @diff;
    fail("$path has fewer than four substantive added/removed lines")
        if @content < 4;
}

my @instruction_files = ('AGENTS.md', glob('.agents/skills/*/SKILL.md'));
push @instruction_files, grep { -f $_ } glob('.github/agents/*.agent.md');
for my $file (@instruction_files) {
    open my $fh, '<', $file or fail("cannot read $file: $!");
    local $/;
    my $text = <$fh> // '';
    close $fh;
    if ($file =~ m{/SKILL\.md$}) {
        fail("$file lacks YAML frontmatter") unless $text =~ /\A---\n.*?\n---\n/s;
        fail("$file lacks Maintenance & Continuous Learning")
            unless $text =~ /^## Maintenance & Continuous Learning\s*$/m;
    }
    if ($file eq 'AGENTS.md') {
        fail("AGENTS.md lacks Continuous Agent & Skills Maintenance")
            unless $text =~ /^## Continuous Agent & Skills Maintenance\s*$/m;
    }
    while ($text =~ /\[[^\]]*\]\(([^)]+)\)/g) {
        my $target = $1;
        next if $target =~ m{\A(?:https?://|mailto:|#)};
        $target =~ s/#.*\z//;
        next unless length $target;
        my $resolved = File::Spec->catfile(dirname($file), split m{/}, $target);
        fail("$file links to missing path $target") unless -e $resolved;
    }
}

print "PASS: ", scalar(@changed), " changed paths; ", scalar(@instruction_changes),
    " instruction files changed; structure and local links valid.\n";
print "Semantic relevance still requires human review.\n";
exit 0;

sub git_lines {
    my @cmd = ('git', @_,);
    open my $fh, '-|', @cmd or die "run @cmd: $!\n";
    my @lines = <$fh>;
    close $fh or die "command failed (@cmd)\n";
    chomp @lines;
    return @lines;
}
sub fail { die "FAIL: $_[0]\n"; }
