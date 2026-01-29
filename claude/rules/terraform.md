---
paths: terraform/**/*.tf
---

# Terraform Coding Guidelines

## File Naming

| Filename | Purpose |
|----------|---------|
| `providers.tf` | Provider configuration |
| `backend.tf` | Backend configuration |
| `variables.tf` | Input variables (external input only) |
| `locals.tf` | Local values (internal values) |
| `outputs.tf` | Output values |
| `data.tf` | Data sources |
| `<resource>.tf` | Individual resource definitions |
| `import.tf` / `moved.tf` / `removed.tf` | Temporary blocks (delete after apply) |

**Do not use `main.tf`** - Split resources by type/purpose.

## Variables vs Locals

- **`variables.tf`**: Only for values passed from outside (CLI, tfvars, module calls)
- **`locals.tf`**: For internal values, computed values, constants

## Resource Block Order

1. `count` / `for_each`
2. Resource-specific arguments
3. Block arguments
4. `lifecycle`
5. `depends_on`

## Key Rules

| Rule | Description |
|------|-------------|
| `depends_on` | Only use for implicit dependencies (no attribute reference exists) |
| Security Groups | Use `aws_vpc_security_group_*_rule` resources, not inline blocks |
| IAM Policies | Use `aws_iam_policy_document` data source, not inline JSON |

For detailed patterns, examples, and best practices, use `/terraform-patterns` skill.
