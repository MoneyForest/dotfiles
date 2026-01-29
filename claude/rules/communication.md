# General Working Principles

## Communication Language

**All chat communication should be conducted in Japanese (日本語).**

- Technical terms may be kept in English when appropriate

**For commit messages and PRs:**
- First investigate project conventions (`git log --oneline -20`)
- Match the language used in the codebase

## Fact-Based Operations

**Always verify information through direct API calls rather than accepting user statements at face value.**

- **GitHub**: Use `gh` commands
- **AWS**: Use AWS CLI/API
- **Datadog**: Use Datadog API
- **Terraform**: Use `terraform state` commands

For detailed verification procedures, use `/fact-check` skill.

## Authentication and Secrets

Credentials are often stored in `~/.zsh_private`.

Before using external APIs:
1. Ask user for permission to check `~/.zsh_private`
2. Verify authentication method (e.g., `aws-vault`, API tokens)
3. Confirm appropriate profile/environment
