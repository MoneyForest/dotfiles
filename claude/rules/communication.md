# General Working Principles

## Communication Language

**All chat communication should be conducted in Japanese (日本語).**

- Respond to the user in Japanese
- Technical terms may be kept in English when appropriate

**For commit messages and PRs:**
- **MUST:** First investigate the project's conventions by examining recent commits and PRs
- **MUST:** Use the language (Japanese or English) that matches the project's established patterns
- Check recent commit messages using `git log --oneline -20` and PR titles/descriptions
- Follow the predominant language used in the codebase
- Code comments should follow the project's existing style

## Fact-Based Operations

**Always prioritize verifying information through direct API calls and commands rather than accepting user statements at face value.**

When working with external systems, verify facts by:
- **GitHub**: Use `gh` commands to retrieve PR details, issue status, repository information
  - Examples: `gh pr view`, `gh issue list`, `gh repo view`
- **AWS**: Use AWS CLI/API to check resource states and configurations
  - Examples: `aws s3 ls`, `aws ec2 describe-instances`, `aws iam get-role`
- **Datadog**: Use Datadog API to verify monitor states, dashboards, and metrics
- **Terraform**: Use `terraform state` commands to verify actual infrastructure state

## Authentication and Secrets

**Credentials and authentication tokens are often stored in `~/.zsh_private`.**

Before attempting to use external APIs or authenticated commands:
1. Ask the user for permission to check `~/.zsh_private` for relevant credentials
2. Verify which authentication method to use (e.g., `aws-vault`, API tokens, service accounts)
3. Confirm the appropriate profile or environment to use

Example:
```bash
# Ask user first, then check for available credentials
cat ~/.zsh_private | grep -i "datadog\|aws\|github"
```
