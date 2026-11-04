#!/usr/bin/env perl
# Black-box contract tests for validate-agent-knowledge.pl.

use strict;
use warnings;
use utf8;

use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir tempfile);
use JSON::PP qw(decode_json);
use Test::More;

my $SOURCE_ROOT = File::Spec->rel2abs(
    File::Spec->catdir(dirname(__FILE__), File::Spec->updir(), File::Spec->updir())
);
my $VALIDATOR = File::Spec->catfile($SOURCE_ROOT, 'scripts', 'validate-agent-knowledge.pl');

my $AGENT_TEXT = <<'AGENT';
# Repository guidance

## Continuous Agent & Skills Maintenance

Keep operational guidance accurate and reusable.

See [the readme](README.md).
AGENT

my $SKILL_TEXT = <<'SKILL';
---
name: example
description: Guidance for the example subsystem.
---
# Example skill

## Maintenance & Continuous Learning

Keep the procedure current.
SKILL

my @created_directories;

sub write_file {
    my ($path, $content) = @_;
    my $parent = dirname($path);
    make_path($parent) unless -d $parent;
    open my $handle, '>:encoding(UTF-8)', $path or die "open $path: $!";
    print {$handle} $content;
    close $handle or die "close $path: $!";
}

sub git_command {
    my ($repo, @arguments) = @_;
    open my $handle, '-|', 'git', '-C', $repo, @arguments
        or die "cannot run git: $!";
    local $/;
    my $output = <$handle>;
    close $handle;
    die "git @arguments failed" if $?;
    $output = '' unless defined $output;
    return $output;
}

sub new_fixture {
    my $temporary = tempdir(CLEANUP => 1);
    push @created_directories, $temporary;
    my $repo = File::Spec->catdir($temporary, 'repo');
    make_path(File::Spec->catdir($repo, 'scripts'));
    copy($VALIDATOR, File::Spec->catfile($repo, 'scripts', 'validate-agent-knowledge.pl'))
        or die "copy validator: $!";
    git_command($repo, 'init', '-q', '-b', 'main');
    git_command($repo, 'config', 'user.name', 'Validator Test');
    git_command($repo, 'config', 'user.email', 'validator@example.invalid');
    write_file(File::Spec->catfile($repo, 'AGENTS.md'), $AGENT_TEXT);
    write_file(File::Spec->catfile($repo, 'README.md'), "Repository fixture.\n");
    write_file(File::Spec->catfile($repo, 'src', 'example.txt'), "VALUE = 1\n");
    write_file(File::Spec->catfile($repo, '.agents', 'skills', 'example', 'SKILL.md'), $SKILL_TEXT);
    git_command($repo, 'add', '-A');
    git_command($repo, 'commit', '-q', '-m', 'baseline');
    my $base = git_command($repo, 'rev-parse', 'HEAD');
    $base =~ s/^\s+|\s+$//g;
    return { repo => $repo, base => $base, temporary => $temporary };
}

sub write_in_fixture {
    my ($fixture, $relative, $content) = @_;
    write_file(File::Spec->catfile($fixture->{repo}, split m{/}, $relative), $content);
}

sub commit_fixture {
    my ($fixture, $message) = @_;
    git_command($fixture->{repo}, 'add', '-A');
    git_command($fixture->{repo}, 'commit', '-q', '-m', $message);
}

sub run_validator {
    my ($fixture, @arguments) = @_;
    my ($stdout_handle, $stdout_file) = tempfile();
    my ($stderr_handle, $stderr_file) = tempfile();
    my $cwd = $fixture->{cwd} || $fixture->{repo};
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        open STDOUT, '>&', $stdout_handle or exit 127;
        open STDERR, '>&', $stderr_handle or exit 127;
        chdir $cwd or exit 127;
        exec $^X, File::Spec->catfile($fixture->{repo}, 'scripts', 'validate-agent-knowledge.pl'),
            @arguments;
        exit 127;
    }
    waitpid($pid, 0);
    my $status = $? >> 8;
    seek $stdout_handle, 0, 0;
    seek $stderr_handle, 0, 0;
    local $/;
    my $stdout = <$stdout_handle>;
    my $stderr = <$stderr_handle>;
    $stdout = '' unless defined $stdout;
    $stderr = '' unless defined $stderr;
    return { status => $status, stdout => $stdout, stderr => $stderr };
}

sub update_agent {
    my ($fixture) = @_;
    write_in_fixture($fixture, 'AGENTS.md',
        $AGENT_TEXT . "\nWhen parser boundaries change, update examples and rerun compatibility review.\n");
}

# 1. Clean worktree passes.
{
    my $fixture = new_fixture();
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'clean worktree passes');
    like($result->{stdout}, qr/Status: PASS/, 'clean worktree reports PASS');
    like($result->{stdout}, qr/Errors: 0/, 'clean worktree reports zero errors');
}

# 2. Code change without a knowledge update fails AK001.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'code change without knowledge update fails');
    like($result->{stdout}, qr/\[FAIL\] AK001/, 'AK001 fails without knowledge update');
}

# 3. Code change with an AGENTS.md update passes with AK004 warning.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    update_agent($fixture);
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'code change with AGENTS update passes');
    like($result->{stdout}, qr/\[PASS\] AK001/, 'AK001 passes with AGENTS update');
    like($result->{stdout}, qr/\[WARN\] AK004/, 'AK004 warns for human review');
}

# 4. Code change with a skill update passes.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    my $skill_path = File::Spec->catfile($fixture->{repo}, '.agents', 'skills', 'example', 'SKILL.md');
    open my $skill, '<:encoding(UTF-8)', $skill_path or die "open $skill_path: $!";
    local $/;
    my $content = <$skill>;
    close $skill;
    write_in_fixture($fixture, '.agents/skills/example/SKILL.md',
        $content . "\nWhen this parser changes, retain compatibility examples in this skill.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'code change with skill update passes');
}

# 5. Cosmetic knowledge change fails AK001 and AK004.
{
    my $fixture = new_fixture();
    my $changed = $AGENT_TEXT;
    $changed =~ s/operational guidance/operational  guidance/;
    write_in_fixture($fixture, 'AGENTS.md', $changed);
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'cosmetic knowledge change fails');
    like($result->{stdout}, qr/\[FAIL\] AK004/, 'AK004 fails for cosmetic change');
}

# 6. Malformed skill fails AK002.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    update_agent($fixture);
    write_in_fixture($fixture, '.agents/skills/example/SKILL.md',
        "---\nname: example\n---\n# Broken\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'malformed skill fails');
    like($result->{stdout}, qr/\[FAIL\] AK002/, 'AK002 fails for malformed skill');
}

# 7. Broken internal reference fails AK003.
{
    my $fixture = new_fixture();
    update_agent($fixture);
    write_in_fixture($fixture, 'AGENTS.md', $AGENT_TEXT . "\nSee [missing](docs/missing.md).\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'broken link fails');
    like($result->{stdout}, qr/\[FAIL\] AK003/, 'AK003 fails for broken link');
}

# 8. An untracked project file is discovered.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/new.txt', "VALUE = 3\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'untracked project file fails');
    like($result->{stdout}, qr/src\/new\.txt/, 'untracked file is listed');
}

# 9. A renamed project file is discovered.
{
    my $fixture = new_fixture();
    git_command($fixture->{repo}, 'mv', 'src/example.txt', 'src/renamed.txt');
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'renamed project file fails');
    like($result->{stdout}, qr/\[FAIL\] AK001/, 'AK001 fails for rename');
}

# 10. A deleted project file is discovered.
{
    my $fixture = new_fixture();
    unlink File::Spec->catfile($fixture->{repo}, 'src', 'example.txt');
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'deleted project file fails');
    like($result->{stdout}, qr/src\/example\.txt/, 'deleted file is listed');
}

# 11. Staged and unstaged changes are combined.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    git_command($fixture->{repo}, 'add', 'src/example.txt');
    update_agent($fixture);
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'staged and unstaged changes are combined');
}

# 12. A valid range uses base and head.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    update_agent($fixture);
    commit_fixture($fixture, 'code and knowledge');
    my $head = git_command($fixture->{repo}, 'rev-parse', 'HEAD');
    $head =~ s/^\s+|\s+$//g;
    my $result = run_validator($fixture, '--scope', 'range',
        '--base', $fixture->{base}, '--head', $head);
    is($result->{status}, 0, 'valid range passes');
}

# 13. A missing revision returns an execution error.
{
    my $fixture = new_fixture();
    my $result = run_validator($fixture, '--scope', 'range',
        '--base', 'missing', '--head', 'HEAD');
    is($result->{status}, 2, 'missing revision returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'missing revision fails AK005');
}

# 14. Invalid configuration returns an execution error.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\ncontract_version = \"9.9.9\"\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'invalid configuration returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'invalid configuration fails AK005');
}

# 15. Incompatible CLI arguments return a usage error.
{
    my $fixture = new_fixture();
    my $result = run_validator($fixture, '--scope', 'range', '--base', $fixture->{base});
    is($result->{status}, 2, 'incomplete range returns 2');
    like($result->{stderr}, qr/requires both --base and --head/, 'usage error names the missing option');
}

# 16. Help documents the stable CLI.
{
    my $fixture = new_fixture();
    my $result = run_validator($fixture, '--help');
    is($result->{status}, 0, 'help exits zero');
    like($result->{stdout}, qr/--scope \{worktree,range\}/, 'help documents --scope');
    like($result->{stdout}, qr/--format \{text,json\}/, 'help documents --format');
}

# 17. Running outside a Git repository returns an execution error.
{
    my $fixture = new_fixture();
    my $outside = tempdir(CLEANUP => 1);
    $fixture->{cwd} = $outside;
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'outside repository returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'outside repository fails AK005');
}

# 18. JSON output is machine-readable.
{
    my $fixture = new_fixture();
    my $result = run_validator($fixture, '--scope', 'worktree', '--format', 'json');
    is($result->{status}, 0, 'JSON run exits zero');
    my $report = eval { decode_json($result->{stdout}) };
    ok($report, 'JSON output decodes');
    is($report->{schema_version}, '1.0', 'JSON schema version is stable');
    is($report->{contract_version}, '2.0.0', 'JSON contract version is current');
    is($report->{status}, 'PASS', 'JSON status is PASS');
    is(scalar @{ $report->{checks} }, 7, 'JSON contains seven checks');
}

# 19. An explicit exclusion prevents AK001.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nexclude_paths = [\"generated/**\"]\n");
    commit_fixture($fixture, 'configure generated path exclusion');
    write_in_fixture($fixture, 'generated/output.txt', "Generated output.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'excluded path does not trigger AK001');
}

# 20. Conflicting directives are reported as a warning.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'AGENTS.md', $AGENT_TEXT
        . "\nOperators must retain exclusive control of validation results.\n"
        . "Operators must not retain exclusive control of validation results.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'conflicting directives do not fail the gate');
    like($result->{stdout}, qr/\[WARN\] AK006/, 'AK006 warns about conflicts');
}

# 21. Configured strict text rules are enforced under AKX001.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\n[validator.strict_text]\n\"AGENTS.md\" = [\"no_trailing_whitespace\"]\n");
    write_in_fixture($fixture, 'AGENTS.md', $AGENT_TEXT . "trailing   \n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'strict text violation fails');
    like($result->{stdout}, qr/\[FAIL\] AKX001/, 'AKX001 enforces strict text');
}

# 22. Configured inline path checks reject missing repository paths.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\ninline_path_checks = true\n");
    write_in_fixture($fixture, 'AGENTS.md', $AGENT_TEXT . "\nSee `docs/missing.md`.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'missing inline path fails');
    like($result->{stdout}, qr/\[FAIL\] AKX001/, 'AKX001 checks inline paths');
}

# 23. A configured required heading is enforced.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\n[validator.required_headings]\n\"AGENTS.md\" = [\"Deployment Policy\"]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'missing configured heading fails');
    like($result->{stdout}, qr/\[FAIL\] AK002/, 'AK002 enforces configured headings');
}

# 24. UTF-8 instruction content is accepted without corruption.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    write_in_fixture($fixture, 'AGENTS.md',
        $AGENT_TEXT . "\nVerifica la configuración y conserva los ejemplos.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'UTF-8 knowledge update passes');
    unlike($result->{stdout}, qr/\x{fffd}/, 'UTF-8 output is not replaced');
}

# 25. A change limited to the validator itself is exempt from AK001.
{
    my $fixture = new_fixture();
    my $validator = File::Spec->catfile($fixture->{repo}, 'scripts', 'validate-agent-knowledge.pl');
    open my $handle, '>>:encoding(UTF-8)', $validator or die "open $validator: $!";
    print {$handle} "\n# fixture-only comment\n";
    close $handle;
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'validator-only change is exempt from AK001');
    like($result->{stdout}, qr/\[PASS\] AK001/, 'AK001 exempts validator infrastructure');
}

# 26. Absolute and parent-traversing configuration paths are rejected.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nexclude_paths = [\"/tmp/**\"]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'absolute exclusion path returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'absolute exclusion path fails AK005');
}

# 27. A parent-traversing strict-text pattern is rejected.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\n[validator.strict_text]\n\"../AGENTS.md\" = [\"lf_only\"]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'parent-traversing pattern returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'parent-traversing pattern fails AK005');
}

# 28. JSON output preserves non-ASCII paths without double encoding.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'src/café.txt', "VALUE = 2\n");
    my $result = run_validator($fixture, '--scope', 'worktree', '--format', 'json');
    is($result->{status}, 1, 'non-ASCII project file fails AK001');
    my $report = eval { decode_json($result->{stdout}) };
    ok($report, 'non-ASCII JSON decodes');
    my @files = @{ $report->{errors}[0]{files} || [] };
    ok((grep { $_ eq 'src/café.txt' } @files), 'non-ASCII path is not mojibaked');
}

# 29. TOML scalar types are enforced for string arrays.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nexclude_paths = [1]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'non-string exclusion entry returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'non-string exclusion entry fails AK005');
}

# 30. Duplicate TOML keys and tables are rejected.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nminimum_changed_lines = 1\nminimum_changed_lines = 2\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'duplicate TOML key returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'duplicate key fails AK005');
}
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\n[validator]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 2, 'duplicate TOML table returns 2');
    like($result->{stdout}, qr/\[FAIL\] AK005/, 'duplicate table fails AK005');
}

# 31. An empty configuration file uses the documented defaults.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml', "\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'empty configuration is accepted');
    unlike($result->{stdout}, qr/\[FAIL\] AK005/, 'empty configuration is not an execution error');
}

# 32. Unicode escapes in configuration strings are decoded.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\n[validator.required_headings]\n"
        . "\"AGENTS.md\" = [\"Caf\\u00e9 Policy\"]\n");
    write_in_fixture($fixture, 'AGENTS.md',
        $AGENT_TEXT . "\n## Café Policy\n\nKeep the café policy current and rerun compatibility review.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'unicode escape heading passes');
    unlike($result->{stdout}, qr/\[FAIL\] AK002/, 'unicode escape is decoded for AK002');
}

# 33. Configured required phrases are enforced.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\n[validator.required_phrases]\n"
        . "\"AGENTS.md\" = [\"Keep operational guidance accurate and reusable\"]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    unlike($result->{stdout}, qr/\[FAIL\] AK002/, 'present required phrase passes AK002');
}

# 34. Configured skill-reference prefixes are enforced.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nskill_reference_prefixes = [\"openbsd-\"]\n");
    write_in_fixture($fixture, 'docs/sub.agent.md',
        "---\nname: sub\ndescription: d\n---\n# Sub\n\n"
        . "## Post-Change Knowledge Synchronization\n\nUse `openbsd-missing`.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    like($result->{stdout}, qr/\[FAIL\] AKX001/, 'missing skill reference fails AKX001');
}

# 35. minimum_changed_lines rejects a short knowledge edit.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nminimum_changed_lines = 5\n");
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    write_in_fixture($fixture, 'AGENTS.md', $AGENT_TEXT . "\nShort note.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'short knowledge edit fails the minimum');
    like($result->{stdout}, qr/\[FAIL\] AK001/, 'minimum_changed_lines fails AK001');
}

# 36. Custom instruction globs participate in AK001.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\ninstruction_globs = [\"docs/*.md\"]\n");
    write_in_fixture($fixture, 'src/example.txt', "VALUE = 2\n");
    write_in_fixture($fixture, 'docs/policy.md',
        "# Policy\n\nWhen parser boundaries change, update examples and rerun review.\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'custom instruction glob satisfies AK001');
}

# 37. Exact duplicate instruction files are reported under AK006.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'docs/AGENTS.md', $AGENT_TEXT);
    my $result = run_validator($fixture, '--scope', 'worktree');
    like($result->{stdout}, qr/\[WARN\] AK006/, 'duplicate instructions warn under AK006');
}

# 38. Percent-encoded, fragment and absolute links resolve.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, 'docs/a b.md', "# A\n");
    write_in_fixture($fixture, 'AGENTS.md',
        $AGENT_TEXT . "\nSee [space](docs/a%20b.md), [anchor](README.md#top), and [abs](/README.md).\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 0, 'encoded, fragment and absolute links pass');
    unlike($result->{stdout}, qr/\[FAIL\] AK003/, 'AK003 accepts valid link forms');
}

# 39. A symlink escaping the repository fails AK003.
{
    my $fixture = new_fixture();
    my $outside = File::Spec->catfile($fixture->{temporary}, 'outside.md');
    write_file($outside, "outside\n");
    make_path(File::Spec->catdir($fixture->{repo}, 'docs'));
    symlink($outside, File::Spec->catfile($fixture->{repo}, 'docs', 'link.md'))
        or die "symlink: $!";
    write_in_fixture($fixture, 'AGENTS.md', $AGENT_TEXT . "\nSee [escape](docs/link.md).\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'symlink escape fails');
    like($result->{stdout}, qr/\[FAIL\] AK003/, 'AK003 rejects symlink escape');
}

# 40. An invalid fnmatch range is treated as a non-match, not a crash.
{
    my $fixture = new_fixture();
    write_in_fixture($fixture, '.agent-knowledge-validator.toml',
        "[validator]\nexclude_paths = [\"[z-a]\"]\n");
    my $result = run_validator($fixture, '--scope', 'worktree');
    is($result->{status}, 1, 'invalid fnmatch range does not crash');
    unlike($result->{stdout}, qr/\[FAIL\] AK005/, 'invalid fnmatch range is not an execution error');
}

done_testing();
