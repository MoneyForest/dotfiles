---
name: skill-creator
description: Guide for creating Claude Code skills with best practices. Use when creating new skills, writing skill descriptions, or setting up skill directories. Trigger phrases: 'create a skill', 'new skill', 'skill template', 'スキルを作成', '新しいスキル'.
metadata:
  author: MoneyForest
  version: 1.0.0
  category: development-tools
  tags: [claude-code, skills, templates, documentation]
---

# Skill Creator Guide

Create effective Claude Code skills following best practices from "The Complete Guide to Building Skills for Claude".

## Quick Start

### 1. Create Directory Structure

```bash
claude/skills/<skill-name>/
├── SKILL.md           # Required: Main skill file
└── references/        # Optional: Supporting files
    └── *.md
```

### 2. Frontmatter Template (Required)

```yaml
---
name: <skill-name>
description: <what it does>. <when to use>. Trigger phrases: '<phrase1>', '<phrase2>', '<日本語フレーズ>'.
metadata:
  author: <author>
  version: 1.0.0
  category: <category>
  tags: [<tag1>, <tag2>]
---
```

## Description Best Practices

The `description` field is **critical** for skill discovery. Claude uses it to decide when to activate the skill.

### Formula

```
[What it does] + [When to use] + [Trigger phrases]
```

### Good Examples

```yaml
# Specific, actionable, with triggers
description: DDD + Clean Architecture patterns for Go applications including domain models, usecases, repositories, and error handling. Use when designing Go services, implementing business logic, or structuring new projects. Trigger phrases: 'go patterns', 'golang architecture', 'DDD', 'clean architecture', 'Go設計'.

description: AWS infrastructure security best practices with Terraform examples covering IAM, Security Groups, S3, and RDS. Use when configuring security policies, reviewing infrastructure code, or hardening AWS resources. Trigger phrases: 'aws security', 'iam policy', 's3 security', 'AWSセキュリティ', 'セキュリティグループ'.
```

### Bad Examples

```yaml
# Too vague - Claude can't determine when to use
description: Helpful patterns for development.

# Missing "when to use"
description: Go application patterns.

# No trigger phrases
description: Terraform best practices for AWS infrastructure.
```

### Trigger Phrase Design

1. **Include English and Japanese** for bilingual users
2. **Be specific** - use terms users would actually say
3. **Cover variations** - abbreviations, full names, synonyms
4. **3-5 phrases** is optimal

```yaml
# Good trigger phrases
Trigger phrases: 'terraform modules', 'tf patterns', 'infrastructure as code', 'Terraform設計', 'モジュール設計'.

# Too few
Trigger phrases: 'terraform'.

# Too many (dilutes relevance)
Trigger phrases: 'terraform', 'tf', 'hcl', 'infrastructure', 'cloud', 'aws', 'modules', 'patterns', 'best practices', 'design'.
```

## Optional Metadata

```yaml
metadata:
  author: <GitHub username or name>
  version: <semver>
  category: <see categories below>
  tags: [<relevant>, <keywords>]
```

### Categories

| Category | Use For |
|----------|---------|
| `development` | Language-specific patterns, coding guidelines |
| `infrastructure` | AWS, Terraform, CI/CD, cloud resources |
| `review` | Code review, self-review, quality checks |
| `workflow` | Work processes, dialogue patterns |
| `documentation` | Doc generation, templates |
| `development-tools` | Meta-tools, utilities |

### Tags

Use lowercase, hyphenated tags that describe:
- Technologies: `golang`, `terraform`, `aws`, `github-actions`
- Concepts: `clean-architecture`, `ddd`, `security`
- Use cases: `code-review`, `infrastructure`, `patterns`

## File Structure

### Progressive Disclosure

Put essential content in `SKILL.md`, detailed references in `references/`:

```
claude/skills/terraform-patterns/
├── SKILL.md                      # Core patterns (loaded by default)
└── references/
    ├── module-design.md          # Deep dive: module patterns
    ├── state-management.md       # Deep dive: state handling
    └── testing-strategies.md     # Deep dive: testing
```

Claude loads `SKILL.md` first. Use explicit references to load additional files:

```markdown
For detailed module patterns, see `references/module-design.md`.
```

### Naming Conventions

- **Directory**: lowercase, hyphenated (`skill-name/`)
- **Main file**: Always `SKILL.md`
- **References**: descriptive, hyphenated (`topic-name.md`)

## Content Guidelines

### Structure

```markdown
# Skill Title

Brief description of the skill's purpose.

## When to Activate

- Scenario 1
- Scenario 2
- Scenario 3

## Core Content

Main patterns, guidelines, or procedures.

### Subsection

Details with code examples.

## References

Link to reference files for deeper content.
```

### Code Examples

Always include practical examples:

```markdown
### Good Pattern

\`\`\`go
// Descriptive comment
func Example() {
    // Implementation
}
\`\`\`

### Anti-Pattern

\`\`\`go
// Don't do this because...
func BadExample() {
    // Problematic implementation
}
\`\`\`
```

## Troubleshooting

### Skill Not Discovered

1. Check `name` matches directory name
2. Verify description includes clear use cases
3. Add more specific trigger phrases
4. Ensure YAML frontmatter syntax is valid

### Skill Activated Incorrectly

1. Make description more specific
2. Narrow trigger phrases
3. Add explicit "Use when" criteria

### References Not Loading

1. Check file path is correct relative to skill directory
2. Ensure file exists and is readable
3. Use explicit path: `references/filename.md`

## Checklist

Before publishing a skill:

- [ ] `name` in frontmatter matches directory name
- [ ] `description` follows formula: what + when + triggers
- [ ] Trigger phrases include English and Japanese
- [ ] `metadata` block has author, version, category, tags
- [ ] Content has clear "When to Activate" section
- [ ] Code examples show good and bad patterns
- [ ] Large content split into references/ directory
