---
paths: ".github/workflows/**/*.yml"
---

# GitHub Actions 3-Layer Architecture

## Layer Structure

| Layer | File Pattern | Role |
|-------|-------------|------|
| Layer 1 | `_*.yml` | Reusable workflow (`workflow_call`) - shared logic |
| Layer 2 | `*-{env}.yml` | Caller workflows - environment-specific parameters |
| Layer 3 | `composites/` | Composite actions - individual steps |

## Naming Conventions

- **Reusable workflows**: Prefix with `_` (e.g., `_cd.yml`, `_terraform.yml`)
- **Caller workflows**: Include environment (e.g., `cd-dev.yml`, `cd-prd.yml`)
- **Composite actions**: Place in `composites/` or `.github/actions/`

## Benefits

- **DRY**: Common logic in Layer 1, environment values in Layer 2
- **Maintainability**: Changes to deploy process only need Layer 1 updates
- **Visibility**: Each environment has its own workflow with clear triggers
- **Concurrency**: Each caller can define its own concurrency group

For detailed patterns, OIDC setup, and examples, use `/github-actions-patterns` skill.
