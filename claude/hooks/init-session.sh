#!/bin/bash
set -e

if [ -f ~/.claude/settings.json ]; then
  echo "=== Global Settings ==="
  cat ~/.claude/settings.json
fi

if [ -f "./CLAUDE.md" ]; then
  echo "--- Repository CLAUDE.md ---"
  cat ./CLAUDE.md
fi
