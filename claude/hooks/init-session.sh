#!/bin/bash
cat ~/.claude/CLAUDE.md
cat ~/.claude/settings.json

# Check for repository-level CLAUDE.md
if [ -f "./CLAUDE.md" ]; then
  echo "--- Repository CLAUDE.md ---"
  cat ./CLAUDE.md
fi
