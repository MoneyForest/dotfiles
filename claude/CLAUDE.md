# Claude Code Instructions

This project uses modular rule files organized in the `claude/rules/` directory.

## Rules (Always Loaded)

Minimal, essential rules loaded into every session:

- `rules/00-session-init.md` - Session initialization
- `rules/communication.md` - Language and fact-based operations
- `rules/git-commit.md` - Commit message format
- `rules/terraform.md` - Terraform coding conventions
- `rules/github-actions.md` - GitHub Actions 3-layer architecture

## Skills (On-Demand)

Detailed patterns and examples loaded when needed:

- `/commit-guidelines` - Detailed commit guidelines with Seven Rules and examples
- `/terraform-patterns` - Terraform design patterns and coding examples
- `/github-actions-patterns` - GitHub Actions implementation patterns
- `/fact-check` - Verification procedures for Datadog, AWS, Terraform
- `/aws-security` - AWS security best practices with Terraform examples
- `/aws-terraform-review` - Infrastructure change review checklist
- `/golang-patterns` - Go DDD + Clean Architecture patterns
- `/repo-init` - Repository initialization utilities (gitignore, project structure)

The rules are automatically loaded by Claude Code through the `.claude/rules` symlink.
