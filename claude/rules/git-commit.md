# Git/PR Guidelines

## Commit Message Format

Follow [Angular Commit Message Format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format).

```
<type>(<scope>): <summary>
```

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code refactoring |
| `chore` | Other changes |

**Scope**: Optional. Use area-based (e.g., `api`, `frontend`, `terraform`, `ci`), not action-based.

**Summary**: Imperative mood, no trailing period, max 72 chars.

## Signature Policy

**DO NOT** include these signatures:
- `Generated with [Claude Code]`
- `Co-Authored-By: Claude`

## Key Rules

1. **Concise and clear** - Avoid verbose expressions
2. **Imperative mood** - "Add feature" not "Added feature"
3. **Body explains why** - Code shows how, commit explains why
4. **Investigate conventions first** - Check `git log --oneline -20` for project style

For detailed guidelines, examples, and Seven Rules, use `/commit-guidelines` skill.
