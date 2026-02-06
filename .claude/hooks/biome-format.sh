#!/usr/bin/env bash
# Auto-format files after Write/Edit using Biome
# Called as a PostToolUse hook — must never block (always exit 0)

set -euo pipefail

# Read JSON from stdin (provided by Claude Code hooks)
INPUT=$(cat)

# Extract file_path from the tool result
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only format supported file types
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist (was deleted)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Find biome binary: local node_modules first, then bunx fallback
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

if [ -x "$REPO_ROOT/node_modules/.bin/biome" ]; then
  "$REPO_ROOT/node_modules/.bin/biome" format --write "$FILE_PATH" 2>/dev/null || true
else
  bunx --bun @biomejs/biome format --write "$FILE_PATH" 2>/dev/null || true
fi

exit 0
