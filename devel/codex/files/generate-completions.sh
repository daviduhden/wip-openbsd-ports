#!/bin/sh
# Generate shell completions from the freshly built codex binary.

set -eu

: "${WRKBUILD:?}"

cd "$WRKBUILD/target/release"
for shell_name in bash fish zsh; do
	./codex completion "$shell_name" > "codex.$shell_name"
done
