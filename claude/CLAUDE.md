# CRITICAL: MANDATORY SESSION INITIALIZATION

IMPORTANT: YOU MUST EXECUTE THIS IMMEDIATELY AT THE START OF EVERY SESSION AS YOUR FIRST ACTION, BEFORE RESPONDING TO ANY USER MESSAGE.

Read `~/.claude/settings.json` to understand the permission settings and constraints that govern all your actions in this session.

This file contains critical allow/deny rules for:
- Bash commands (git, terraform, aws-vault, etc.)
- File access patterns
- Destructive operations that require user approval

FAILURE TO READ THIS FILE AT SESSION START IS UNACCEPTABLE.

---

## General Working Principles

### Communication Language

**All chat communication should be conducted in Japanese (日本語).**

- Respond to the user in Japanese
- Code comments and documentation can remain in English as per project conventions
- Technical terms may be kept in English when appropriate

### Fact-Based Operations

**Always prioritize verifying information through direct API calls and commands rather than accepting user statements at face value.**

When working with external systems, verify facts by:
- **GitHub**: Use `gh` commands to retrieve PR details, issue status, repository information
  - Examples: `gh pr view`, `gh issue list`, `gh repo view`
- **AWS**: Use AWS CLI/API to check resource states and configurations
  - Examples: `aws s3 ls`, `aws ec2 describe-instances`, `aws iam get-role`
- **Datadog**: Use Datadog API to verify monitor states, dashboards, and metrics
- **Terraform**: Use `terraform state` commands to verify actual infrastructure state

### Authentication and Secrets

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

---

## Git/PR Guidelines

### Commit Message Format

Follow the [Angular Commit Message Format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format).

### Commit/PR Title

```
<type>(<scope>): <summary>
```

| Type       | Description                  |
| ---------- | ---------------------------- |
| `feat`     | New feature                  |
| `fix`      | Bug fix                      |
| `docs`     | Documentation only           |
| `refactor` | Code refactoring             |
| `chore`    | Other changes                |

- **Scope**: Target scope of the change (optional)
  - Examples: `aws/bot_prd`, `datadog`, `frontend`, `api`
- **Summary**: Simple description, no trailing period

Examples:
- `feat(api): add user authentication`
- `fix(frontend): correct login form validation`
- `docs: add setup instructions to README`

### Pull Request Description

Write PR descriptions following the Pull Request Template (`.github/pull_request_template.md` if it exists) with concise, clear explanations:

- Keep descriptions brief and focused on the changes made
- Follow any project-specific PR template structure
- Include relevant context for reviewers
- Link related issues when applicable

---

## Terraform Coding Guidelines

### File Naming Conventions

| Filename          | Purpose                                    |
| ----------------- | ------------------------------------------ |
| `providers.tf`    | Provider configuration                     |
| `backend.tf`      | Backend configuration                      |
| `terraform.tf`    | Version constraints                        |
| `variables.tf`    | Input variables                            |
| `outputs.tf`      | Output values                              |
| `locals.tf`       | Local values                               |
| `data.tf`         | Data sources                               |
| `import.tf`       | Import blocks (delete after apply)         |
| `moved.tf`        | Moved blocks (delete after apply)          |
| `removed.tf`      | Removed blocks (delete after apply)        |
| `<resource>.tf`   | Individual resource definitions            |

### Resource Definitions

- Do not use `main.tf`
- Split resources by type/purpose into separate files (e.g., `ecs_cluster.tf`, `s3_log.tf`)

### Variables vs Locals

**Use `locals.tf` for values that don't need to be passed from outside. Only use `variables.tf` for values that must be configurable externally.**

- **`variables.tf`**: For input variables that need to be passed from outside (e.g., via CLI, tfvars files, or module calls)
- **`locals.tf`**: For internal values, computed values, or constants that don't need external input

```hcl
# BAD: Using variables.tf for internal-only values
# variables.tf
variable "app_name" {
  default = "myapp"  # This never changes and isn't passed from outside
}

# GOOD: Use locals.tf for internal-only values
# locals.tf
locals {
  app_name = "myapp"
}

# GOOD: Use variables.tf only when external input is needed
# variables.tf
variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}
```

### Resource Block Argument Order

Follow the [HashiCorp Style Guide](https://developer.hashicorp.com/terraform/language/style):

1. `count` / `for_each`
2. Resource-specific arguments
3. Block arguments
4. `lifecycle`
5. `depends_on`

### depends_on Usage

- **Do not use `depends_on` when dependencies are resolved through references**
- Terraform automatically resolves dependencies through attribute references (e.g., `aws_s3_bucket.log.id`)
- Use `depends_on` only for implicit dependencies (when no reference exists)

```hcl
# BAD: depends_on is redundant because bucket attribute reference exists
resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  depends_on = [aws_s3_bucket.log]  # Unnecessary
}

# GOOD: Dependencies are automatically resolved through reference
resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
}
```

### Security Group Rule Definitions

For Security Group rules, use **separate resources** instead of inline blocks (`ingress`/`egress`).

Use the following newer resource types:

- `aws_vpc_security_group_ingress_rule` - Inbound rules
- `aws_vpc_security_group_egress_rule` - Outbound rules

**Note**: Do not use the older `aws_security_group_rule`.

```hcl
# BAD: Inline block definition
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# GOOD: Separate resource definition
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "example_https" {
  security_group_id = aws_security_group.example.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
```

### IAM Policy Definitions

**Avoid inline policies** for IAM and define them using `aws_iam_policy_document` data sources:

```hcl
# BAD: Inline policy (hardcoded JSON)
resource "aws_iam_role_policy" "example" {
  name = "example"
  role = aws_iam_role.example.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [...]
  })
}

# GOOD: Define with aws_iam_policy_document
data "aws_iam_policy_document" "example" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::example-bucket/*"]
  }
}

resource "aws_iam_policy" "example" {
  name   = "example"
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}
```
