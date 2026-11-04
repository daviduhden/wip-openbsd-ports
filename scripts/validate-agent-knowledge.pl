#!/usr/bin/env perl
# Validate the shared Agent Knowledge Validation contract.
#
# This is the Perl implementation of contract 2.0.0.  It replaces the
# canonical Python validator with the same CLI, rule identifiers, output
# schema, and exit codes.  Only core Perl modules are used.

use strict;
use warnings;
use utf8;

use Cwd qw(abs_path getcwd);
use Encode qw(decode encode FB_CROAK FB_DEFAULT);
use File::Basename qw(basename dirname);
use File::Spec;
use Getopt::Long qw(GetOptionsFromArray);
use IO::Select;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

our $CONTRACT_VERSION = '2.0.0';
our $SCHEMA_VERSION   = '1.0';
our $CONFIG_NAME      = '.agent-knowledge-validator.toml';

my %RULE_NAMES = (
    AK001 => 'Agent knowledge synchronization',
    AK002 => 'Agent and skill structure',
    AK003 => 'Internal references',
    AK004 => 'Knowledge update relevance',
    AK005 => 'Validator configuration and execution',
    AK006 => 'Duplicate or conflicting instructions',
);

my %INSTRUCTION_NAMES = map { $_ => 1 } (
    'AGENTS.md', 'AGENT.md', 'SKILL.md', 'CLAUDE.md', 'GEMINI.md',
    'copilot-instructions.md', '.cursorrules', '.windsurfrules',
);
my @INSTRUCTION_SUFFIXES = ('.agent.md', '.instructions.md', '.mdc');

my @INFRASTRUCTURE_PATTERNS = (
    'scripts/validate-agent-knowledge.pl',
    '**/scripts/validate-agent-knowledge.pl',
    'tests/agent_knowledge_validator/**',
    '**/tests/agent_knowledge_validator/**',
    '.github/workflows/agent-knowledge-validation.yml',
    '**/agent-knowledge-validation.yml',
    '**/agent-knowledge-validation.yaml',
);

my @DEFAULT_EXCLUDED_PATHS = ('__pycache__/**', '**/__pycache__/**');

my $METADATA_RE = qr{^(?:updated?|generated|last[ -]updated|date|updated_at)\s*[:=]}i;
my $LINK_RE     = qr{(?<!!)\[[^\]]*\]\(([^)]+)\)};
my $CONFLICT_RE = qr{^\s*(.*?)\b(must not|mustn't|must|should not|should|do not|don't|never|always)\b\s+([^.!?]{12,})[.!?]?\s*$}i;

# Mark TOML strings so configuration validation can distinguish them from
# integers and booleans instead of relying on truthiness.
{
    package AK::TomlString;
    sub new {
        my ($class, $value) = @_;
        return bless \$value, $class;
    }
    sub value { return ${ $_[0] }; }
}

sub is_toml_string {
    return ref($_[0]) eq 'AK::TomlString';
}

sub toml_string {
    my ($value) = @_;
    return undef unless is_toml_string($value);
    return $value->value;
}

# ---------------------------------------------------------------------------
# Errors and small utilities

sub validation_error {
    my ($message) = @_;
    die "ValidationError: $message\n";
}

sub is_validation_error {
    my ($error) = @_;
    return defined($error) && $error =~ /\AValidationError: /;
}

sub error_message {
    my ($error) = @_;
    $error =~ s/\AValidationError: //;
    $error =~ s/\n\z//;
    return $error;
}

sub sorted_unique {
    my %seen;
    return [ sort grep { !$seen{$_}++ } @_ ];
}

sub path_parts {
    my ($path) = @_;
    return grep { length } split m{/}, $path;
}

sub path_name {
    my ($path) = @_;
    my @parts = path_parts($path);
    return @parts ? $parts[-1] : '';
}

sub path_parent_name {
    my ($path) = @_;
    my @parts = path_parts($path);
    return @parts >= 2 ? $parts[-2] : '';
}

sub is_absolute_posix {
    my ($path) = @_;
    return $path =~ m{\A/};
}

sub has_parent_component {
    my ($path) = @_;
    return scalar grep { $_ eq '..' } path_parts($path);
}

sub path_suffix {
    my ($path) = @_;
    my $name = path_name($path);
    return '' if $name eq '' || $name =~ /\A\.+\z/;
    my $index = rindex($name, '.');
    return '' if $index <= 0 || $index == length($name) - 1;
    return substr($name, $index);
}

sub lexical_absolute {
    my ($path) = @_;
    my $absolute = is_absolute_posix($path) ? $path : File::Spec->rel2abs($path);
    my @parts;
    for my $segment (split m{/}, $absolute) {
        next if $segment eq '' || $segment eq '.';
        if ($segment eq '..') {
            pop @parts if @parts;
            next;
        }
        push @parts, $segment;
    }
    return '/' . join('/', @parts);
}

sub within_root {
    my ($path, $root) = @_;
    return 1 if $path eq $root;
    return index($path, $root . '/') == 0;
}
sub resolve_lenient {
    my ($path) = @_;
    my $current = $path;
    my @suffix;
    while (!-e $current) {
        my $parent = dirname($current);
        return lexical_absolute($path) if $parent eq $current || $parent eq '.';
        unshift @suffix, basename($current);
        $current = $parent;
    }
    my $resolved = abs_path($current);
    return lexical_absolute($path) unless defined $resolved;
    return File::Spec->catfile($resolved, @suffix);
}


sub percent_decode {
    my ($value) = @_;
    my $bytes = encode('UTF-8', $value);
    $bytes =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return decode('UTF-8', $bytes, FB_DEFAULT);
}

# Python's fnmatch.fnmatchcase is not path-aware: '*' also matches '/'.
sub fnmatch_case {
    my ($name, $pattern) = @_;
    my $regex = _fnmatch_regex($pattern);
    my $matched = eval { $name =~ /\A$regex\z/s ? 1 : 0 };
    return defined($matched) ? $matched : 0;
}

sub _fnmatch_regex {
    my ($pattern) = @_;
    my $out = '';
    my $i   = 0;
    my $n   = length($pattern);
    while ($i < $n) {
        my $char = substr($pattern, $i, 1);
        if ($char eq '*') {
            $out .= '.*';
            $i++;
            next;
        }
        if ($char eq '?') {
            $out .= '.';
            $i++;
            next;
        }
        if ($char eq '[') {
            my $j     = $i + 1;
            my $neg   = '';
            my $class = '';
            my $closed = 0;
            if ($j < $n && substr($pattern, $j, 1) eq '!') {
                $neg = '^';
                $j++;
            }
            if ($j < $n && substr($pattern, $j, 1) eq ']') {
                $class .= '\]';
                $j++;
            }
            while ($j < $n) {
                my $inner = substr($pattern, $j, 1);
                if ($inner eq ']') {
                    $closed = 1;
                    $j++;
                    last;
                }
                if ($inner eq '\\') {
                    # fnmatch treats backslash as an ordinary character.
                    $class .= '\\\\';
                    $j++;
                    next;
                }
                if ($inner eq '-' || $inner =~ /[A-Za-z0-9]/) {
                    $class .= $inner;
                }
                else {
                    $class .= quotemeta($inner);
                }
                $j++;
            }
            if ($closed) {
                $out .= '[' . $neg . $class . ']';
                $i = $j;
            }
            else {
                $out .= '\[';
                $i++;
            }
            next;
        }
        $out .= quotemeta($char);
        $i++;
    }
    return $out;
}

# ---------------------------------------------------------------------------
# Git integration (never through a shell)

sub run_git {
    my ($root, @arguments) = @_;
    my ($writer, $reader, $error_handle);
    my $error_symbol = gensym;
    my $pid = open3($writer, $reader, $error_symbol, 'git', '-C', $root, @arguments);
    close $writer;
    binmode $reader;
    binmode $error_symbol;
    my $stdout = '';
    my $stderr = '';
    my $selector = IO::Select->new($reader, $error_symbol);
    while ($selector->count) {
        for my $handle ($selector->can_read) {
            my $buffer = '';
            my $read = sysread($handle, $buffer, 8192);
            if (!defined $read || $read == 0) {
                $selector->remove($handle);
                next;
            }
            if (fileno($handle) == fileno($reader)) {
                $stdout .= $buffer;
            }
            else {
                $stderr .= $buffer;
            }
        }
    }
    $stdout = decode('UTF-8', $stdout, FB_DEFAULT);
    $stderr = decode('UTF-8', $stderr, FB_DEFAULT);
    waitpid($pid, 0);
    my $status = $? >> 8;
    return ($status, $stdout, $stderr);
}

sub run_git_checked {
    my ($root, @arguments) = @_;
    my ($status, $stdout, $stderr) = run_git($root, @arguments);
    if ($status != 0) {
        my $detail = $stderr;
        $detail =~ s/^\s+|\s+$//g;
        $detail = 'git ' . join(' ', @arguments) . ' failed' if $detail eq '';
        validation_error($detail);
    }
    return $stdout;
}

sub find_repository_root {
    my ($cwd) = @_;
    my $output = run_git_checked($cwd, 'rev-parse', '--show-toplevel');
    $output =~ s/^\s+|\s+$//g;
    my $resolved = abs_path($output);
    validation_error('cannot resolve repository root') unless defined $resolved;
    return $resolved;
}

sub resolve_commit {
    my ($root, $revision) = @_;
    my ($status, $stdout) = run_git($root, 'rev-parse', '--verify', $revision . '^{commit}');
    if ($status != 0) {
        validation_error("revision does not resolve to a commit: $revision");
    }
    $stdout =~ s/^\s+|\s+$//g;
    return $stdout;
}

sub parse_name_status {
    my ($raw) = @_;
    my @fields = split /\0/, $raw, -1;
    my @changes;
    my $index = 0;
    while ($index + 1 < @fields) {
        my $status = $fields[$index];
        my $path   = $fields[$index + 1];
        $index += 2;
        next if !length($status) || !length($path);
        push @changes, { status => substr($status, 0, 1), path => $path };
    }
    return \@changes;
}

sub deduplicate_changes {
    my ($changes) = @_;
    my %by_path;
    for my $change (@$changes) {
        $by_path{ $change->{path} } = $change;
    }
    return [ map { $by_path{$_} } sort keys %by_path ];
}

sub discover_changes {
    my ($root, $scope, $base, $head) = @_;
    if ($scope eq 'worktree') {
        my $tracked = run_git_checked(
            $root, 'diff', '--name-status', '-z', '--no-renames', 'HEAD'
        );
        my @changes = @{ parse_name_status($tracked) };
        my $untracked = run_git_checked(
            $root, 'ls-files', '--others', '--exclude-standard', '-z'
        );
        push @changes, map { { status => 'A', path => $_ } }
            grep { length } split /\0/, $untracked;
        return deduplicate_changes(\@changes);
    }
    validation_error('range scope requires a base and a head') unless defined $base && defined $head;
    my $base_commit = resolve_commit($root, $base);
    my $head_commit = resolve_commit($root, $head);
    my $merge_base = run_git_checked($root, 'merge-base', $base_commit, $head_commit);
    $merge_base =~ s/^\s+|\s+$//g;
    my $raw = run_git_checked(
        $root, 'diff', '--name-status', '-z', '--no-renames', $merge_base, $head_commit
    );
    return deduplicate_changes(parse_name_status($raw));
}

sub read_text_strict {
    my ($path) = @_;
    open my $handle, '<:raw', $path or die "open $path: $!\n";
    local $/;
    my $raw = <$handle>;
    close $handle;
    $raw = '' unless defined $raw;
    return decode('UTF-8', $raw, FB_CROAK);
}

sub try_read_text {
    my ($path) = @_;
    my $text = eval { read_text_strict($path) };
    return (0, undef) if $@;
    return (1, $text);
}

sub changed_content {
    my ($root, $scope, $base, $head, $path) = @_;
    my $diff;
    if ($scope eq 'range') {
        validation_error('range scope requires a base and a head') unless defined $base && defined $head;
        my $base_commit = resolve_commit($root, $base);
        my $head_commit = resolve_commit($root, $head);
        my $merge_base = run_git_checked($root, 'merge-base', $base_commit, $head_commit);
        $merge_base =~ s/^\s+|\s+$//g;
        $diff = run_git_checked(
            $root, 'diff', '--no-ext-diff', '--unified=0',
            $merge_base, $head_commit, '--', $path
        );
    }
    else {
        $diff = run_git_checked(
            $root, 'diff', '--no-ext-diff', '--unified=0', 'HEAD', '--', $path
        );
    }

    my (@added, @removed);
    for my $line (split_lines($diff)) {
        next if $line =~ /\A(?:\+\+\+|---)/;
        if ($line =~ /\A\+/) {
            my $normalized = normalize_knowledge_line(substr($line, 1));
            push @added, $normalized if length $normalized;
        }
        elsif ($line =~ /\A-/) {
            my $normalized = normalize_knowledge_line(substr($line, 1));
            push @removed, $normalized if length $normalized;
        }
    }

    if ($scope eq 'worktree' && $diff eq '') {
        my $discovered = discover_changes($root, $scope, $base, $head);
        my ($is_present) = grep { $_->{path} eq $path } @$discovered;
        if ($is_present) {
            my $candidate = File::Spec->catfile($root, $path);
            if (-f $candidate) {
                my ($status) = run_git(
                    $root, 'ls-files', '--error-unmatch', '--', $path
                );
                if ($status != 0) {
                    my ($ok, $text) = try_read_text($candidate);
                    if ($ok) {
                        for my $line (split_lines($text)) {
                            my $normalized = normalize_knowledge_line($line);
                            push @added, $normalized if length $normalized;
                        }
                    }
                }
            }
        }
    }
    return (\@added, \@removed);
}

sub split_lines {
    my ($text) = @_;
    return () if $text eq '';
    my @lines;
    while ($text =~ s/\A(.*?)(\r\n|[\n\r\x0b\x0c\x1c\x1d\x1e\x{85}\x{2028}\x{2029}])//s) {
        push @lines, $1;
    }
    push @lines, $text if length $text;
    return @lines;
}

sub normalize_knowledge_line {
    my ($line) = @_;
    $line =~ s/^\s+|\s+$//g;
    return '' if $line eq '';
    return '' if $line =~ /\A(?:#|<!--|-->)/;
    return '' if $line =~ $METADATA_RE;
    return '' if $line =~ /\A[-*_`~>| ]+\z/;
    $line =~ s/\s+/ /g;
    $line =~ s/^\s+|\s+$//g;
    return $line;
}

sub update_metrics {
    my ($added, $removed) = @_;
    my %available;
    $available{$_}++ for @$added;
    my @remaining_removed;
    for my $old (@$removed) {
        if ($available{$old}) {
            $available{$old}--;
        }
        else {
            push @remaining_removed, $old;
        }
    }
    my @changed = (@remaining_removed);
    push @changed, map { ($_) x $available{$_} } keys %available;
    my $effective_chars = 0;
    for my $line (@changed) {
        my $alphanumeric = $line;
        $alphanumeric =~ s/[^A-Za-z0-9]//g;
        $effective_chars += length($alphanumeric);
    }
    return (scalar @changed, $effective_chars);
}

sub substantive_update {
    my ($added, $removed, $minimum_lines) = @_;
    my ($line_count, $effective_chars) = update_metrics($added, $removed);
    return $line_count >= $minimum_lines && $effective_chars >= 24;
}

sub discover_instruction_files {
    my ($root, $extra_globs) = @_;
    my @found;
    my $walk;
    $walk = sub {
        my ($directory, $relative) = @_;
        opendir my $handle, $directory or return;
        my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $handle;
        closedir $handle;
        for my $name (@entries) {
            next if $name eq '.git';
            my $absolute = File::Spec->catfile($directory, $name);
            my $path = length($relative) ? "$relative/$name" : $name;
            my @stat = lstat($absolute);
            next unless @stat;
            next if -l _;
            if (-d _) {
                $walk->($absolute, $path);
            }
            elsif (-f _ && is_instruction($path, $extra_globs)) {
                push @found, $path;
            }
        }
    };
    $walk->($root, '');
    return [ sort @found ];
}

sub is_instruction {
    my ($path, $extra_globs) = @_;
    my $name = path_name($path);
    return 1 if $INSTRUCTION_NAMES{$name};
    for my $suffix (@INSTRUCTION_SUFFIXES) {
        return 1 if length($name) >= length($suffix)
            && substr($name, -length($suffix)) eq $suffix;
    }
    my %parts = map { $_ => 1 } path_parts($path);
    if (path_parent_name($path) eq 'rules'
        && ($parts{'.cursor'} || $parts{'.windsurf'} || $parts{'.continue'})) {
        return 1;
    }
    return 1 if $path eq '.agents/skills/README.md';
    for my $pattern (@$extra_globs) {
        return 1 if fnmatch_case($path, $pattern);
    }
    return 0;
}

sub is_excluded {
    my ($path, $patterns) = @_;
    for my $pattern (@$patterns) {
        return 1 if fnmatch_case($path, $pattern);
    }
    return 0;
}

# ---------------------------------------------------------------------------
# Minimal TOML reader for the documented validator configuration subset.

sub strip_toml_comment {
    my ($line) = @_;
    my $out = '';
    my $quote = '';
    my $escaped = 0;
    for my $char (split //, $line) {
        if ($quote eq '"') {
            if ($escaped) {
                $out .= $char;
                $escaped = 0;
                next;
            }
            if ($char eq '\\') {
                $out .= $char;
                $escaped = 1;
                next;
            }
            if ($char eq '"') {
                $quote = '';
            }
            $out .= $char;
            next;
        }
        if ($quote eq "'") {
            $quote = '' if $char eq "'";
            $out .= $char;
            next;
        }
        if ($char eq '#' ) {
            last;
        }
        if ($char eq '"' || $char eq "'") {
            $quote = $char;
        }
        $out .= $char;
    }
    return $out;
}

sub split_toml_dotted {
    my ($value) = @_;
    my @parts;
    my $current = '';
    my $quote = '';
    for my $char (split //, $value) {
        if ($quote) {
            $current .= $char;
            $quote = '' if $char eq $quote;
            next;
        }
        if ($char eq '"' || $char eq "'") {
            $quote = $char;
            $current .= $char;
            next;
        }
        if ($char eq '.') {
            push @parts, $current;
            $current = '';
            next;
        }
        $current .= $char;
    }
    push @parts, $current if length $current;
    for my $part (@parts) {
        $part =~ s/^\s+|\s+$//g;
        if ($part =~ /\A"(.*)"\z/s || $part =~ /\A'(.*)'\z/s) {
            $part = $1;
        }
    }
    return @parts;
}

sub toml_brackets_open {
    my ($value) = @_;
    my $depth = 0;
    my $quote = '';
    my $escaped = 0;
    for my $char (split //, $value) {
        if ($quote eq '"') {
            if ($escaped) { $escaped = 0; next; }
            if ($char eq '\\') { $escaped = 1; next; }
            $quote = '' if $char eq '"';
            next;
        }
        if ($quote eq "'") {
            $quote = '' if $char eq "'";
            next;
        }
        if ($char eq '"' || $char eq "'") { $quote = $char; next; }
        $depth++ if $char eq '[' || $char eq '{';
        $depth-- if $char eq ']' || $char eq '}';
    }
    return $depth > 0;
}

sub split_toml_array {
    my ($value) = @_;
    my @items;
    my $current = '';
    my $quote = '';
    my $escaped = 0;
    my $depth = 0;
    for my $char (split //, $value) {
        if ($quote eq '"') {
            $current .= $char;
            if ($escaped) { $escaped = 0; next; }
            if ($char eq '\\') { $escaped = 1; next; }
            $quote = '' if $char eq '"';
            next;
        }
        if ($quote eq "'") {
            $current .= $char;
            $quote = '' if $char eq "'";
            next;
        }
        if ($char eq '"' || $char eq "'") {
            $quote = $char;
            $current .= $char;
            next;
        }
        if ($char eq '[' || $char eq '{') { $depth++; $current .= $char; next; }
        if ($char eq ']' || $char eq '}') { $depth--; $current .= $char; next; }
        if ($char eq ',' && $depth == 0) {
            push @items, $current;
            $current = '';
            next;
        }
        $current .= $char;
    }
    push @items, $current if $current =~ /\S/;
    return @items;
}

sub parse_toml_value {
    my ($value) = @_;
    $value =~ s/^\s+|\s+$//g;
    return JSON::PP::true() if $value eq 'true';
    return JSON::PP::false() if $value eq 'false';
    if ($value =~ /\A"(.*)"\z/s) {
        my $string = $1;
        my %escapes = (
            'n' => "\n", 't' => "\t", 'r' => "\r", '"' => '"',
            '\\' => '\\', 'b' => "\b", 'f' => "\f",
        );
        validation_error("invalid escape in TOML string")
            if $string =~ /\\(?!u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8}|[ntr"\\bf])/;
        $string =~ s/\\(u([0-9A-Fa-f]{4})|U([0-9A-Fa-f]{8})|[ntr"\\bf])/
            defined($2) ? chr(hex($2)) : defined($3) ? chr(hex($3)) : $escapes{$1}/ge;
        return AK::TomlString->new($string);
    }
    if ($value =~ /\A'(.*)'\z/s) {
        return AK::TomlString->new($1);
    }
    if ($value =~ /\A\[(.*)\]\z/s) {
        my $inside = $1;
        my @items = split_toml_array($inside);
        return [ map { parse_toml_value($_) } @items ];
    }
    if ($value =~ /\A\{(.*)\}\z/s) {
        my $inside = $1;
        my %table;
        for my $item (split_toml_array($inside)) {
            next unless $item =~ /\S/;
            validation_error("invalid inline table entry: $item")
                unless $item =~ /\A(.*?)\s*=\s*(.*)\z/s;
            my ($key, $entry) = ($1, $2);
            my @keys = split_toml_dotted($key);
            my $reference = \%table;
            for my $part (@keys[0 .. $#keys - 1]) {
                $reference->{$part} = {} unless exists $reference->{$part};
                validation_error('inline table key conflicts with a value')
                    unless ref($reference->{$part}) eq 'HASH';
                $reference = $reference->{$part};
            }
            validation_error("duplicate TOML key in inline table: $key")
                if exists $reference->{ $keys[-1] };
            $reference->{ $keys[-1] } = parse_toml_value($entry);
        }
        return \%table;
    }
    if ($value =~ /\A([-+]?)0x([0-9A-Fa-f](?:_?[0-9A-Fa-f])*)\z/) {
        my ($sign, $digits) = ($1, $2);
        $digits =~ s/_//g;
        my $number = hex($digits);
        return $sign eq '-' ? -$number : $number;
    }
    if ($value =~ /\A([-+]?)0o([0-7](?:_?[0-7])*)\z/) {
        my ($sign, $digits) = ($1, $2);
        $digits =~ s/_//g;
        my $number = oct("0$digits");
        return $sign eq '-' ? -$number : $number;
    }
    if ($value =~ /\A([-+]?)0b([01](?:_?[01])*)\z/) {
        my ($sign, $digits) = ($1, $2);
        $digits =~ s/_//g;
        my $number = oct("0b$digits");
        return $sign eq '-' ? -$number : $number;
    }
    if ($value =~ /\A([-+]?)([0-9](?:_?[0-9])*)\z/) {
        my ($sign, $digits) = ($1, $2);
        $digits =~ s/_//g;
        return $sign eq '-' ? -$digits : 0 + $digits;
    }
    validation_error("unsupported TOML value: $value");
}

sub parse_toml {
    my ($text) = @_;
    my %root;
    my %declared;
    my $current = \%root;
    my @lines = split /\n/, $text, -1;
    for (my $index = 0; $index < @lines; $index++) {
        my $line = strip_toml_comment($lines[$index]);
        $line =~ s/^\s+|\s+$//g;
        next if $line eq '';
        if ($line =~ /\A\[([^\]]+)\]\z/) {
            my $section = $1;
            $section =~ s/^\s+|\s+$//g;
            my @parts = split_toml_dotted($section);
            validation_error('only the [validator] table is supported')
                unless @parts && $parts[0] eq 'validator';
            my $canonical = join('.', @parts);
            validation_error("duplicate TOML table: $section") if $declared{$canonical};
            $declared{$canonical} = 1;
            my $reference = \%root;
            for my $part (@parts) {
                $reference->{$part} = {} unless exists $reference->{$part};
                validation_error("[$section] conflicts with a value")
                    unless ref($reference->{$part}) eq 'HASH';
                $reference = $reference->{$part};
            }
            $current = $reference;
            next;
        }
        if ($line =~ /\A(.*?)\s*=\s*(.*)\z/s) {
            my ($key, $value) = ($1, $2);
            $key =~ s/^\s+|\s+$//g;
            my @keys = split_toml_dotted($key);
            validation_error('empty TOML key') unless @keys;
            while (toml_brackets_open($value)) {
                $index++;
                validation_error('unterminated TOML array') if $index >= @lines;
                $value .= "\n" . strip_toml_comment($lines[$index]);
            }
            my $parsed = parse_toml_value($value);
            my $reference = $current;
            for my $part (@keys[0 .. $#keys - 1]) {
                $reference->{$part} = {} unless exists $reference->{$part};
                validation_error('TOML dotted key conflicts with a value')
                    unless ref($reference->{$part}) eq 'HASH';
                $reference = $reference->{$part};
            }
            validation_error("duplicate TOML key: $key")
                if exists $reference->{ $keys[-1] };
            $reference->{ $keys[-1] } = $parsed;
            next;
        }
        validation_error("unsupported TOML syntax: $line");
    }
    return \%root;
}

sub parse_config {
    my ($root) = @_;
    my $path = File::Spec->catfile($root, $CONFIG_NAME);
    my %defaults = (
        exclude_paths            => [],
        instruction_globs        => [],
        required_headings        => {},
        required_phrases         => {},
        strict_text              => {},
        skill_reference_prefixes => [],
        inline_path_checks       => 0,
        minimum_changed_lines    => 1,
    );
    return \%defaults unless -e $path;

    my ($ok, $text) = try_read_text($path);
    validation_error("$CONFIG_NAME: cannot read UTF-8 configuration") unless $ok;
    my $value = eval { parse_toml($text) };
    validation_error("$CONFIG_NAME: " . error_message($@)) if $@;

    return \%defaults unless keys %$value;

    my @top = sort keys %$value;
    if (grep { $_ ne 'validator' } @top) {
        validation_error("$CONFIG_NAME: only the [validator] table is supported");
    }
    my $settings = $value->{validator};
    validation_error("$CONFIG_NAME: [validator] must be a table")
        unless defined $settings && ref($settings) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(
        contract_version exclude_paths instruction_globs required_headings
        required_phrases strict_text skill_reference_prefixes
        inline_path_checks minimum_changed_lines
    );
    my @unknown = sort grep { !$allowed{$_} } keys %$settings;
    validation_error("$CONFIG_NAME: unknown setting(s): " . join(', ', @unknown))
        if @unknown;

    my $version = exists $settings->{contract_version}
        ? toml_string($settings->{contract_version}) : $CONTRACT_VERSION;
    if (!defined $version || $version ne $CONTRACT_VERSION) {
        my $shown = defined $version ? "'$version'" : 'non-string';
        validation_error("$CONFIG_NAME: contract_version must be '$CONTRACT_VERSION' (found $shown)");
    }

    my %parsed;
    for my $key (qw(exclude_paths instruction_globs)) {
        my $items = exists $settings->{$key} ? $settings->{$key} : [];
        validation_error("$CONFIG_NAME: $key must be an array of non-empty strings")
            unless ref($items) eq 'ARRAY';
        my @plain;
        for my $item (@$items) {
            my $text = toml_string($item);
            validation_error("$CONFIG_NAME: $key must be an array of non-empty strings")
                unless defined $text && $text =~ /\S/;
            validation_error("$CONFIG_NAME: $key entries must be repository-relative: $text")
                if is_absolute_posix($text) || has_parent_component($text);
            push @plain, $text;
        }
        $parsed{$key} = \@plain;
    }

    for my $key (qw(required_headings required_phrases)) {
        my $mapping = exists $settings->{$key} ? $settings->{$key} : {};
        validation_error("$CONFIG_NAME: $key must be a table of paths to arrays")
            unless ref($mapping) eq 'HASH';
        my %validated;
        for my $path (sort keys %$mapping) {
            validation_error("$CONFIG_NAME: $key paths must be repository-relative: $path")
                if is_absolute_posix($path) || has_parent_component($path);
            my $values = $mapping->{$path};
            validation_error("$CONFIG_NAME: $key.$path must be an array of non-empty strings")
                unless ref($values) eq 'ARRAY';
            my @plain;
            for my $value (@$values) {
                my $text = toml_string($value);
                validation_error("$CONFIG_NAME: $key.$path must be an array of non-empty strings")
                    unless defined $text && $text =~ /\S/;
                push @plain, $text;
            }
            $validated{$path} = \@plain;
        }
        $parsed{$key} = \%validated;
    }

    my $known = discover_instruction_files($root, $parsed{instruction_globs});
    my %known_paths = map { $_ => 1 } @$known;
    for my $key (qw(required_headings required_phrases)) {
        my @unknown_paths = sort grep { !$known_paths{$_} } keys %{ $parsed{$key} };
        validation_error("$CONFIG_NAME: $key references unknown instruction path(s): "
                . join(', ', @unknown_paths))
            if @unknown_paths;
    }

    my $strict_text = exists $settings->{strict_text} ? $settings->{strict_text} : {};
    validation_error("$CONFIG_NAME: strict_text must be a table")
        unless ref($strict_text) eq 'HASH';
    my %allowed_text = map { $_ => 1 } qw(
        ascii_only lf_only final_newline no_trailing_whitespace no_nul
    );
    my %parsed_strict;
    for my $pattern (sort keys %$strict_text) {
        validation_error("$CONFIG_NAME: invalid strict_text pattern: $pattern")
            if is_absolute_posix($pattern) || has_parent_component($pattern);
        my $rules = $strict_text->{$pattern};
        validation_error("$CONFIG_NAME: strict_text.$pattern has an unknown rule")
            unless ref($rules) eq 'ARRAY';
        my @plain;
        for my $rule (@$rules) {
            my $text = toml_string($rule);
            validation_error("$CONFIG_NAME: strict_text.$pattern has an unknown rule")
                unless defined $text && $allowed_text{$text};
            push @plain, $text;
        }
        $parsed_strict{$pattern} = \@plain;
    }
    $parsed{strict_text} = \%parsed_strict;

    my $prefixes = exists $settings->{skill_reference_prefixes}
        ? $settings->{skill_reference_prefixes} : [];
    validation_error("$CONFIG_NAME: skill_reference_prefixes must be an array")
        unless ref($prefixes) eq 'ARRAY';
    my @plain_prefixes;
    for my $prefix (@$prefixes) {
        my $text = toml_string($prefix);
        validation_error("$CONFIG_NAME: skill_reference_prefixes must be an array")
            unless defined $text && length($text);
        push @plain_prefixes, $text;
    }
    $parsed{skill_reference_prefixes} = \@plain_prefixes;

    my $inline = exists $settings->{inline_path_checks}
        ? $settings->{inline_path_checks} : JSON::PP::false();
    validation_error("$CONFIG_NAME: inline_path_checks must be a boolean")
        unless ref($inline) eq 'JSON::PP::Boolean';
    $parsed{inline_path_checks} = $inline ? 1 : 0;

    my $minimum = exists $settings->{minimum_changed_lines}
        ? $settings->{minimum_changed_lines} : 1;
    validation_error("$CONFIG_NAME: minimum_changed_lines must be an integer from 1 to 1000")
        unless defined($minimum) && !ref($minimum)
            && $minimum =~ /\A\d+\z/ && $minimum >= 1 && $minimum <= 1000;
    $parsed{minimum_changed_lines} = 0 + $minimum;

    return \%parsed;
}

# ---------------------------------------------------------------------------
# Rule implementations

sub parse_frontmatter_fields {
    my ($text) = @_;
    my ($block) = $text =~ /\A---\s*\n(.*?)\n---\s*(?:\n|\z)/s;
    return undef unless defined $block;
    my %fields;
    for my $line (split_lines($block)) {
        if ($line =~ /\A([A-Za-z0-9_-]+):\s*(.*?)\s*\z/) {
            my ($key, $value) = ($1, $2);
            $value =~ s/^["']+//;
            $value =~ s/["']+$//;
            $fields{$key} = $value;
        }
    }
    return \%fields;
}

sub has_heading {
    my ($text, $heading) = @_;
    return $text =~ /^##+\s+\Q$heading\E\s*$/m;
}

sub validate_structure {
    my ($root, $paths, $required_headings, $required_phrases) = @_;
    my @errors;
    for my $relative (@$paths) {
        my $path = File::Spec->catfile($root, $relative);
        my ($ok, $text) = try_read_text($path);
        if (!$ok) {
            push @errors, [ $relative, 'cannot read UTF-8 instruction file' ];
            next;
        }
        if ($text =~ /\A\s*\z/) {
            push @errors, [ $relative, 'instruction file is empty' ];
            next;
        }
        for my $heading (@{ $required_headings->{$relative} || [] }) {
            if (!has_heading($text, $heading)) {
                push @errors, [ $relative, "missing configured section: $heading" ];
            }
        }
        for my $phrase (@{ $required_phrases->{$relative} || [] }) {
            my $normalized_text = $text;
            $normalized_text =~ s/\s+/ /g;
            my $normalized_phrase = $phrase;
            $normalized_phrase =~ s/\s+/ /g;
            if (index($normalized_text, $normalized_phrase) < 0) {
                push @errors, [ $relative, "missing configured policy text: $phrase" ];
            }
        }
        my $name = path_name($relative);
        if ($name eq 'AGENTS.md' && $relative eq 'AGENTS.md') {
            if (!has_heading($text, 'Continuous Agent & Skills Maintenance')) {
                push @errors, [ $relative, 'missing Continuous Agent & Skills Maintenance section' ];
            }
        }
        elsif ($name eq 'SKILL.md') {
            my $fields = parse_frontmatter_fields($text);
            if (!defined $fields) {
                push @errors, [ $relative, 'missing or malformed YAML frontmatter delimiters' ];
            }
            else {
                for my $key (qw(name description)) {
                    if (!defined($fields->{$key}) || $fields->{$key} !~ /\S/) {
                        push @errors, [ $relative, "frontmatter requires non-empty $key" ];
                    }
                }
                if (defined($fields->{name}) && $fields->{name} =~ /\S/) {
                    my $trimmed = $fields->{name};
                    $trimmed =~ s/^\s+|\s+$//g;
                    if ($trimmed ne path_parent_name($relative)) {
                        push @errors, [ $relative, 'frontmatter name must match the skill directory' ];
                    }
                }
            }
            if (!has_heading($text, 'Maintenance & Continuous Learning')) {
                push @errors, [ $relative, 'missing Maintenance & Continuous Learning section' ];
            }
        }
        elsif ($name =~ /\.agent\.md\z/) {
            if ($text =~ /\A---/) {
                my $fields = parse_frontmatter_fields($text);
                if (!defined $fields) {
                    push @errors, [ $relative, 'malformed YAML frontmatter delimiters' ];
                }
                elsif (!defined($fields->{name}) || $fields->{name} !~ /\S/
                    || !defined($fields->{description}) || $fields->{description} !~ /\S/) {
                    push @errors, [ $relative, 'agent frontmatter requires name and description' ];
                }
            }
            if (!has_heading($text, 'Post-Change Knowledge Synchronization')) {
                push @errors, [ $relative, 'missing Post-Change Knowledge Synchronization section' ];
            }
        }
    }
    return \@errors;
}

sub validate_extensions {
    my ($root, $paths, $config, $skill_names) = @_;
    my @errors;
    for my $relative (@$paths) {
        my ($ok, $text) = try_read_text(File::Spec->catfile($root, $relative));
        next unless $ok;
        for my $pattern (sort keys %{ $config->{strict_text} }) {
            next unless fnmatch_case($relative, $pattern);
            my %rules = map { $_ => 1 } @{ $config->{strict_text}{$pattern} };
            if ($rules{lf_only} && $text =~ /\r/) {
                push @errors, [ $relative, 'configured text rule requires LF line endings' ];
            }
            if ($rules{final_newline} && length($text) && substr($text, -1) ne "\n") {
                push @errors, [ $relative, 'configured text rule requires a final newline' ];
            }
            if ($rules{no_trailing_whitespace} && $text =~ /[\t ]+$/m) {
                push @errors, [ $relative, 'configured text rule forbids trailing whitespace' ];
            }
            if ($rules{no_nul} && index($text, "\0") >= 0) {
                push @errors, [ $relative, 'configured text rule forbids NUL bytes' ];
            }
            if ($rules{ascii_only}) {
                my $non_ascii = grep { ord($_) > 0x7f } split //, $text;
                if ($non_ascii) {
                    push @errors, [ $relative, 'configured text rule requires ASCII text' ];
                }
            }
        }
    }

    my $prefixes = $config->{skill_reference_prefixes};
    if (@$prefixes) {
        for my $relative (@$paths) {
            next unless $relative =~ /\.agent\.md\z/;
            my ($ok, $text) = try_read_text(File::Spec->catfile($root, $relative));
            next unless $ok;
            while ($text =~ /`([^`]+)`/g) {
                my $reference = $1;
                my $matches = grep { index($reference, $_) == 0 } @$prefixes;
                if ($matches && !$skill_names->{$reference}) {
                    push @errors, [ $relative, "references missing skill: $reference" ];
                }
            }
        }
    }

    if ($config->{inline_path_checks}) {
        my %suffixes = map { $_ => 1 } qw(.md .pl .pm .t .8 .ignore);
        for my $relative (@$paths) {
            my ($ok, $text) = try_read_text(File::Spec->catfile($root, $relative));
            next unless $ok;
            while ($text =~ /`([^`]+)`/g) {
                my $target = $1;
                next if is_absolute_posix($target) || $target =~ /\s/;
                my $suffix = path_suffix($target);
                next unless $suffixes{$suffix}
                    || $target eq 'Makefile' || $target eq 'LICENSE';
                my $parent = File::Spec->catdir($root, dirname($relative));
                my $first  = File::Spec->catfile($parent, $target);
                my $second = File::Spec->catfile($root, $target);
                if (!-e $first && !-e $second) {
                    push @errors, [ $relative, "inline repository path does not exist: $target" ];
                }
            }
        }
    }
    return \@errors;
}

sub validate_references {
    my ($root, $paths) = @_;
    my @errors;
    my $root_resolved = abs_path($root);
    for my $relative (@$paths) {
        my $file_path = File::Spec->catfile($root, $relative);
        my ($ok, $text) = try_read_text($file_path);
        next unless $ok;
        while ($text =~ /$LINK_RE/g) {
            my $target = $1;
            $target =~ s/^\s+|\s+$//g;
            my ($destination) = split /\s+/, $target, 2;
            $destination = '' unless defined $destination;
            $destination =~ s/^[<>]+//;
            $destination =~ s/[<>]+$//;
            next if $destination =~ /\A[A-Za-z][A-Za-z0-9+.\-]*:/;
            next if $destination =~ m{\A//};
            my $local = $destination;
            $local =~ s/[?#].*\z//s;
            next if $local eq '';
            $local = percent_decode($local);
            next if $local eq '';
            my $candidate;
            if (is_absolute_posix($local)) {
                my $stripped = $local;
                $stripped =~ s{\A/+}{};
                $candidate = File::Spec->catfile($root, $stripped);
            }
            else {
                $candidate = File::Spec->catfile(File::Spec->catdir($root, dirname($relative)), $local);
            }
            my $normalized = resolve_lenient($candidate);
            if (!within_root($normalized, $root_resolved)) {
                push @errors, [ $relative, "local reference escapes repository: $destination" ];
                next;
            }
            if (!-e $normalized) {
                push @errors, [ $relative, "broken local reference: $destination" ];
            }
        }
    }
    return \@errors;
}

sub find_duplicate_or_conflicting {
    my ($root, $paths) = @_;
    my (@duplicates, @conflicts);
    my %by_content;
    for my $relative (@$paths) {
        my ($ok, $text) = try_read_text(File::Spec->catfile($root, $relative));
        next unless $ok;
        my $normalized = $text;
        $normalized =~ s/\s+/ /g;
        $normalized =~ s/^\s+|\s+$//g;
        push @{ $by_content{$normalized} }, $relative if length $normalized;

        my %actions;
        for my $line (split_lines($text)) {
            next unless $line =~ $CONFLICT_RE;
            my ($prefix, $modal, $action_text) = ($1, $2, $3);
            my $action = lc($prefix . ' ' . $action_text);
            $action =~ s/[^a-z0-9]+/ /g;
            $action =~ s/^\s+|\s+$//g;
            next if length($action) < 12;
            my $polarity = ($modal =~ /\A(?:must not|mustn't|should not|do not|don't|never)\z/i)
                ? 'negative' : 'positive';
            $actions{$action}{$polarity} = 1;
        }
        for my $action (sort keys %actions) {
            if ($actions{$action}{negative} && $actions{$action}{positive}) {
                push @conflicts, "$relative: explicitly opposite directives for '$action'";
            }
        }
    }
    for my $files (values %by_content) {
        if (@$files > 1) {
            push @duplicates, join(', ', sort @$files);
        }
    }
    @duplicates = sort @duplicates;
    @conflicts  = sort @conflicts;
    return (\@duplicates, \@conflicts);
}

sub make_result {
    my ($rule_id, $status, $message, $files, $remediation) = @_;
    $files = [] unless defined $files;
    my @unique = @{ sorted_unique(@$files) };
    return {
        rule_id     => $rule_id,
        status      => $status,
        message     => $message,
        files       => \@unique,
        remediation => $remediation,
    };
}

sub is_infrastructure_only {
    my ($paths) = @_;
    return 0 unless @$paths;
    for my $path (@$paths) {
        my $matches = 0;
        for my $pattern (@INFRASTRUCTURE_PATTERNS) {
            if (fnmatch_case($path, $pattern)) {
                $matches = 1;
                last;
            }
        }
        return 0 unless $matches;
    }
    return 1;
}

sub run_validation {
    my ($arguments, $cwd) = @_;
    my ($root, $config, $changes, $instruction_paths);
    my $ok = eval {
        $root = find_repository_root($cwd);
        $config = parse_config($root);
        $changes = discover_changes($root, $arguments->{scope}, $arguments->{base}, $arguments->{head});
        $instruction_paths = discover_instruction_files($root, $config->{instruction_globs});
        1;
    };
    if (!$ok) {
        my $detail = error_message($@);
        my @checks = (
            make_result('AK001', 'PASS', 'Agent knowledge synchronization'),
            make_result('AK002', 'PASS', 'Agent and skill structure'),
            make_result('AKX001', 'PASS', 'Configured repository-specific validations'),
            make_result('AK003', 'PASS', 'Internal references'),
            make_result('AK004', 'PASS', 'Knowledge update relevance'),
            make_result('AK005', 'FAIL',
                'Invalid validator configuration or execution error',
                [], 'Check the Git worktree, revisions, and validator configuration.'),
            make_result('AK006', 'PASS', 'No duplicate or conflicting instructions detected'),
        );
        return (\@checks, 2, $detail);
    }

    my @excluded = (@DEFAULT_EXCLUDED_PATHS, @{ $config->{exclude_paths} });
    my @considered = grep { !is_excluded($_->{path}, \@excluded) } @$changes;
    my @changed_paths = map { $_->{path} } @considered;
    my $infrastructure_only = is_infrastructure_only(\@changed_paths);

    my (@knowledge_changes, @project_changes);
    for my $change (@considered) {
        if (is_instruction($change->{path}, $config->{instruction_globs})
            && -f File::Spec->catfile($root, $change->{path})) {
            push @knowledge_changes, $change->{path};
        }
        elsif (!is_instruction($change->{path}, $config->{instruction_globs})) {
            push @project_changes, $change->{path};
        }
    }

    my (@substantive_files, @suspicious_files);
    for my $path (@knowledge_changes) {
        my ($added, $removed) = changed_content(
            $root, $arguments->{scope}, $arguments->{base}, $arguments->{head}, $path
        );
        if (substantive_update($added, $removed, $config->{minimum_changed_lines})) {
            push @substantive_files, $path;
        }
        else {
            push @suspicious_files, $path;
        }
    }

    my $sync;
    if (!@considered || $infrastructure_only) {
        $sync = make_result('AK001', 'PASS', 'Agent knowledge synchronization');
    }
    elsif (@substantive_files) {
        $sync = make_result('AK001', 'PASS', 'Agent knowledge synchronized', \@substantive_files);
    }
    else {
        $sync = make_result('AK001', 'FAIL', 'Missing agent knowledge update',
            @project_changes ? \@project_changes : \@changed_paths,
            'Update a relevant AGENTS.md, agent instruction, or SKILL.md with substantive operational guidance.');
    }

    my $structure_errors = validate_structure(
        $root, $instruction_paths, $config->{required_headings}, $config->{required_phrases}
    );
    my $structure;
    if (@$structure_errors) {
        $structure = make_result('AK002', 'FAIL', 'Invalid agent or skill structure',
            [ map { $_->[0] } @$structure_errors ],
            'Fix the required headings and simple frontmatter fields; frontmatter checks are partial and are not full YAML validation.');
    }
    else {
        $structure = make_result('AK002', 'PASS', 'Agent and skill structure valid');
    }

    my %skill_names;
    for my $relative (@$instruction_paths) {
        next unless path_name($relative) eq 'SKILL.md';
        my ($ok_read, $text) = try_read_text(File::Spec->catfile($root, $relative));
        next unless $ok_read;
        my $fields = parse_frontmatter_fields($text);
        if ($fields && defined($fields->{name}) && $fields->{name} =~ /\S/) {
            my $name = $fields->{name};
            $name =~ s/^\s+|\s+$//g;
            $skill_names{$name} = 1;
        }
    }

    my $extension_errors = validate_extensions(
        $root, $instruction_paths, $config, \%skill_names
    );
    my $extension;
    if (@$extension_errors) {
        $extension = make_result('AKX001', 'FAIL',
            'Configured repository-specific validation failed',
            [ map { $_->[0] } @$extension_errors ],
            'Correct the configured rule or update its documented repository-specific configuration.');
    }
    else {
        $extension = make_result('AKX001', 'PASS',
            'Configured repository-specific validations passed');
    }

    my $reference_errors = validate_references($root, $instruction_paths);
    my $references;
    if (@$reference_errors) {
        $references = make_result('AK003', 'FAIL', 'Broken internal references',
            [ map { $_->[0] } @$reference_errors ],
            'Correct or remove the broken repository-relative Markdown link.');
    }
    else {
        $references = make_result('AK003', 'PASS', 'Internal references valid');
    }

    my $relevance;
    if (@suspicious_files) {
        $relevance = make_result('AK004', 'FAIL',
            'Suspicious knowledge update: no effective content change detected',
            \@suspicious_files,
            'Replace cosmetic or metadata-only edits with substantive operational guidance.');
    }
    elsif (@substantive_files) {
        $relevance = make_result('AK004', 'WARN',
            'Manual relevance review recommended',
            \@substantive_files,
            'Confirm that the instruction update is relevant and reusable; automation cannot prove semantic correctness.');
    }
    else {
        $relevance = make_result('AK004', 'PASS', 'No suspicious knowledge update detected');
    }

    my $configuration = make_result('AK005', 'PASS',
        'Validator configuration and execution valid');

    my ($duplicates, $conflicts) = find_duplicate_or_conflicting($root, $instruction_paths);
    my $conflict_result;
    if (@$duplicates || @$conflicts) {
        my @files;
        push @files, map { split /, /, $_ } @$duplicates;
        push @files, map { (split /:/, $_, 2)[0] } @$conflicts;
        $conflict_result = make_result('AK006', 'WARN',
            'Potential duplicate or conflicting instructions found', \@files,
            'Review the listed instructions and consolidate or clarify only when their scopes truly overlap.');
    }
    else {
        $conflict_result = make_result('AK006', 'PASS',
            'No duplicate or conflicting instructions detected');
    }

    my @results = ($sync, $structure, $extension, $references, $relevance, $configuration, $conflict_result);
    return (\@results, 0, undef);
}

# ---------------------------------------------------------------------------
# Report rendering and CLI

sub make_report {
    my ($checks) = @_;
    my @errors   = grep { $_->{status} eq 'FAIL' } @$checks;
    my @warnings = grep { $_->{status} eq 'WARN' } @$checks;
    return {
        schema_version   => $SCHEMA_VERSION,
        contract_version => $CONTRACT_VERSION,
        status           => @errors ? 'FAIL' : 'PASS',
        summary          => { errors => scalar @errors, warnings => scalar @warnings },
        checks           => [ @$checks ],
        errors           => [ @errors ],
        warnings         => [ @warnings ],
    };
}

sub json_encoder {
    my $json = JSON::PP->new->canonical->pretty;
    $json->indent_length(2);
    $json->space_before('');
    $json->space_after(' ');
    return $json;
}

sub print_report {
    my ($report, $format) = @_;
    if ($format eq 'json') {
        print json_encoder()->encode($report);
        return;
    }
    for my $check (@{ $report->{checks} }) {
        print '[' . $check->{status} . '] ' . $check->{rule_id} . ' - ' . $check->{message} . "\n";
        if (@{ $check->{files} }) {
            print '  Files: ' . join(', ', @{ $check->{files} }) . "\n";
        }
        if (defined $check->{remediation}) {
            print '  Action: ' . $check->{remediation} . "\n";
        }
    }
    print "\nAgent Knowledge Validation\n";
    print 'Status: ' . $report->{status} . "\n";
    print 'Errors: ' . $report->{summary}{errors} . "\n";
    print 'Warnings: ' . $report->{summary}{warnings} . "\n";
}

sub usage {
    return <<"USAGE";
usage: validate-agent-knowledge.pl --scope {worktree,range} [--base BASE] [--head HEAD] [--format {text,json}]

Validate Agent Knowledge contract $CONTRACT_VERSION using only core Perl modules.
USAGE
}

sub main {
    my (@arguments) = @_;
    if (grep { $_ eq '--help' || $_ eq '-h' } @arguments) {
        print usage();
        return 0;
    }
    my %options = (format => 'text');
    my $parser = Getopt::Long::Parser->new(
        config => [qw(no_ignore_case bundling)]
    );
    local $SIG{__WARN__} = sub { };
    my $parsed = $parser->getoptionsfromarray(
        \@arguments,
        'scope=s'  => \$options{scope},
        'base=s'   => \$options{base},
        'head=s'   => \$options{head},
        'format=s' => \$options{format},
        'help|h'   => \$options{help},
    );
    if (!$parsed) {
        print STDERR usage();
        return 2;
    }
    if ($options{help}) {
        print usage();
        return 0;
    }
    if (@arguments) {
        print STDERR 'unrecognized arguments: ' . join(' ', @arguments) . "\n";
        print STDERR usage();
        return 2;
    }
    if (!defined $options{scope}) {
        print STDERR 'the following arguments are required: --scope' . "\n";
        print STDERR usage();
        return 2;
    }
    if ($options{scope} !~ /\A(?:worktree|range)\z/) {
        print STDERR "argument --scope: invalid choice: '$options{scope}' (choose from 'worktree', 'range')\n";
        print STDERR usage();
        return 2;
    }
    if ($options{format} !~ /\A(?:text|json)\z/) {
        print STDERR "invalid choice for --format: $options{format}\n";
        print STDERR usage();
        return 2;
    }
    if ($options{scope} eq 'range'
        && (!defined $options{base} || $options{base} eq ''
            || !defined $options{head} || $options{head} eq '')) {
        print STDERR "--scope range requires both --base and --head\n";
        return 2;
    }
    if ($options{scope} eq 'worktree'
        && ((defined $options{base} && $options{base} ne '')
            || (defined $options{head} && $options{head} ne ''))) {
        print STDERR "--base and --head are only valid with --scope range\n";
        return 2;
    }

    my $cwd = getcwd();
    my ($checks, $execution_code, $detail) = run_validation(\%options, $cwd);
    my $report = make_report($checks);
    print_report($report, $options{format});
    if ($execution_code == 2) {
        if ($options{format} eq 'json') {
            print STDERR 'validator execution error: ' . (defined $detail ? $detail : '') . "\n";
        }
        return 2;
    }
    return $report->{status} eq 'FAIL' ? 1 : 0;
}

exit main(@ARGV);
