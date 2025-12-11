# CRITICAL: MANDATORY SESSION INITIALIZATION

IMPORTANT: YOU MUST EXECUTE THIS IMMEDIATELY AT THE START OF EVERY SESSION AS YOUR FIRST ACTION, BEFORE RESPONDING TO ANY USER MESSAGE.

Read `~/.claude/settings.json` to understand the permission settings and constraints that govern all your actions in this session.

This file contains critical allow/deny rules for:
- Bash commands (git, terraform, aws-vault, etc.)
- File access patterns
- Destructive operations that require user approval

FAILURE TO READ THIS FILE AT SESSION START IS UNACCEPTABLE.
