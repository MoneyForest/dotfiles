# Claude Code Instructions

This project uses modular rule files organized in the `claude/rules/` directory.

All project-specific instructions are split into topic-based files:

- `rules/00-session-init.md` - Session initialization requirements
- `rules/communication.md` - Communication language and fact-based operations
- `rules/git-commit.md` - Git commit message guidelines
- `rules/terraform.md` - Terraform coding standards (applies to `terraform/**/*.tf`)
- `rules/github-actions.md` - GitHub Actions workflow architecture (applies to `.github/workflows/**/*.yml`)
- `rules/dev-tools.md` - Development tools and utilities

The rules are automatically loaded by Claude Code through the `.claude/rules` symlink.
