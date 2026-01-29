---
name: repo-init
description: Repository initialization utilities. Use when creating new projects, setting up gitignore, or initializing development environments.
---

# Repository Initialization

新規リポジトリやプロジェクトの初期化に使用するツールとパターン。

## When to Activate

- 新規プロジェクトの作成
- `.gitignore` の生成
- 開発環境のセットアップ

## gitignore Generation

Use [gibo](https://github.com/simonwhitaker/gibo) to generate `.gitignore` files:

```bash
# List available boilerplates
gibo list

# Generate gitignore for specific languages/tools
gibo dump Go >> .gitignore
gibo dump Node >> .gitignore
gibo dump Python >> .gitignore
gibo dump Terraform >> .gitignore

# Multiple at once
gibo dump Go Node VisualStudioCode >> .gitignore
```

### Common Combinations

| Project Type | Command |
|-------------|---------|
| Go | `gibo dump Go VisualStudioCode >> .gitignore` |
| Node.js | `gibo dump Node >> .gitignore` |
| Python | `gibo dump Python >> .gitignore` |
| Terraform | `gibo dump Terraform >> .gitignore` |

## Project Structure Templates

### Go Project

```bash
mkdir -p cmd internal/domain internal/usecase internal/infrastructure pkg
touch cmd/main.go
go mod init <module-name>
gibo dump Go VisualStudioCode >> .gitignore
```

### Terraform Project

```bash
mkdir -p terraform/aws/{dev,stg,prd}
touch terraform/aws/dev/{backend.tf,providers.tf,locals.tf}
gibo dump Terraform >> .gitignore
```

## Initial Commit

```bash
git init
git add .
git commit -m "feat: initial commit"
```
