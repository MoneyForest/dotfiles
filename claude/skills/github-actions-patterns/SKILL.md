---
name: github-actions-patterns
description: GitHub Actions CI/CD implementation patterns including OIDC authentication, reusable workflows, matrix builds, and caching strategies. Use when designing workflows, implementing secure deployments, or optimizing pipeline performance. Trigger phrases: 'github actions', 'cicd', 'workflow', 'oidc', 'GitHubワークフロー', 'CI/CD設計'.
metadata:
  author: MoneyForest
  version: 1.0.0
  category: infrastructure
  tags: [github-actions, cicd, automation, oidc, workflows]
---

# GitHub Actions CI/CD Patterns

`rules/github-actions.md` は 3 層アーキテクチャを定義。このスキルは実装パターンを提供する。

> **Note**: このスキルは GitHub Actions に特化しています。

## When to Activate

- Terraform CI/CD 設計
- OIDC 認証の実装
- パイプライン最適化
- Reusable Workflow 設計
- 3層アーキテクチャの詳細な例を確認

## Terraform CI/CD Pattern

### Plan on PR, Apply on Merge

```yaml
# _terraform.yml (Reusable Workflow)
name: Terraform

on:
  workflow_call:
    inputs:
      working_directory:
        required: true
        type: string
      environment:
        required: true
        type: string
      aws_role_arn:
        required: true
        type: string

jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ inputs.aws_role_arn }}
          aws-region: ap-northeast-1

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        working-directory: ${{ inputs.working_directory }}
        run: terraform init

      - name: Terraform Plan
        id: plan
        working-directory: ${{ inputs.working_directory }}
        run: |
          terraform plan -no-color -out=tfplan 2>&1 | tee plan.txt
          echo "plan<<EOF" >> $GITHUB_OUTPUT
          cat plan.txt >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const plan = `${{ steps.plan.outputs.plan }}`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `### Terraform Plan (${{ inputs.environment }})\n\`\`\`\n${plan.slice(0, 60000)}\n\`\`\``
            });

  apply:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: plan
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ inputs.aws_role_arn }}
          aws-region: ap-northeast-1

      - uses: hashicorp/setup-terraform@v3

      - name: Terraform Apply
        working-directory: ${{ inputs.working_directory }}
        run: |
          terraform init
          terraform apply -auto-approve
```

### Caller Workflow Example

```yaml
# terraform-dev.yml
name: Terraform Dev

on:
  pull_request:
    paths:
      - 'terraform/aws/dev/**'
  push:
    branches: [main]
    paths:
      - 'terraform/aws/dev/**'

permissions:
  contents: read
  id-token: write
  pull-requests: write

jobs:
  terraform:
    uses: ./.github/workflows/_terraform.yml
    with:
      working_directory: terraform/aws/dev
      environment: dev
      aws_role_arn: arn:aws:iam::123456789012:role/GitHubActionsRole-Dev
```

## OIDC Authentication Pattern

### AWS IAM Role for GitHub Actions

```hcl
# GitHub Actions OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# IAM Role
resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:MyOrg/MyRepo:*"
          }
        }
      }
    ]
  })
}
```

### Environment-Specific Role Restriction

```hcl
# Production は main ブランチのみ許可
resource "aws_iam_role" "github_actions_prod" {
  name = "GitHubActionsRole-Prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # main ブランチのみ
            "token.actions.githubusercontent.com:sub" = "repo:MyOrg/MyRepo:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}
```

## Matrix Build Strategy

### Multi-Environment Matrix

```yaml
jobs:
  test:
    strategy:
      matrix:
        environment: [dev, stg, prd]
        include:
          - environment: dev
            aws_account: "111111111111"
          - environment: stg
            aws_account: "222222222222"
          - environment: prd
            aws_account: "333333333333"
      fail-fast: false
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: |
          echo "Testing ${{ matrix.environment }}"
          echo "Account: ${{ matrix.aws_account }}"
```

### Dynamic Matrix

```yaml
jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      directories: ${{ steps.filter.outputs.directories }}
    steps:
      - uses: actions/checkout@v4
      - id: filter
        run: |
          # 変更されたディレクトリを検出
          dirs=$(git diff --name-only HEAD~1 | grep '^terraform/' | cut -d'/' -f1-3 | sort -u | jq -R -s -c 'split("\n")[:-1]')
          echo "directories=$dirs" >> $GITHUB_OUTPUT

  terraform:
    needs: detect-changes
    if: needs.detect-changes.outputs.directories != '[]'
    strategy:
      matrix:
        directory: ${{ fromJson(needs.detect-changes.outputs.directories) }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Plan
        working-directory: ${{ matrix.directory }}
        run: terraform plan
```

## Caching Strategies

### Go Dependencies

```yaml
- uses: actions/setup-go@v5
  with:
    go-version: '1.22'
    cache: true
    cache-dependency-path: go.sum
```

### Terraform Providers

```yaml
- name: Cache Terraform Providers
  uses: actions/cache@v4
  with:
    path: |
      ~/.terraform.d/plugin-cache
      **/.terraform/providers
    key: terraform-${{ runner.os }}-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      terraform-${{ runner.os }}-
```

### Docker Layer Cache

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and Push
  uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: ${{ env.IMAGE }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Approval Workflow

### Environment Protection

```yaml
jobs:
  deploy-prod:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://app.example.com
    steps:
      - name: Deploy
        run: echo "Deploying to production"
```

GitHub Settings で `production` 環境に承認者を設定する。

### Manual Approval with workflow_dispatch

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
          - dev
          - stg
          - prd
      confirm:
        description: 'Type "deploy" to confirm'
        required: true

jobs:
  deploy:
    if: github.event.inputs.confirm == 'deploy'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: echo "Deploying to ${{ github.event.inputs.environment }}"
```

## Secrets Management

### OIDC > Secrets（推奨順序）

1. **OIDC**: AWS, GCP へのアクセスは OIDC を使用
2. **Environment Secrets**: 環境ごとに異なる値
3. **Repository Secrets**: リポジトリ共通の値

### Secrets の参照

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      # OIDC（Secrets 不要）
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}  # Variables を使用
          aws-region: ap-northeast-1

      # Environment Secret
      - name: Deploy
        run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}  # 環境固有
```

## Reusable Workflow Patterns

### Input Validation

```yaml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      skip_tests:
        required: false
        type: boolean
        default: false

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate inputs
        run: |
          if [[ ! "${{ inputs.environment }}" =~ ^(dev|stg|prd)$ ]]; then
            echo "Invalid environment: ${{ inputs.environment }}"
            exit 1
          fi
```

### Outputs from Reusable Workflow

```yaml
# _build.yml
on:
  workflow_call:
    outputs:
      image_tag:
        description: "Built image tag"
        value: ${{ jobs.build.outputs.tag }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      tag: ${{ steps.build.outputs.tag }}
    steps:
      - id: build
        run: |
          TAG="sha-${GITHUB_SHA::7}"
          echo "tag=$TAG" >> $GITHUB_OUTPUT
```

```yaml
# caller.yml
jobs:
  build:
    uses: ./.github/workflows/_build.yml

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: |
          echo "Deploying image: ${{ needs.build.outputs.image_tag }}"
```

## Security Best Practices

### Permissions

```yaml
# デフォルトを最小に
permissions: {}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read  # 必要なものだけ
```

### Pinned Actions

```yaml
# Good: SHA でピン留め
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1

# Acceptable: Major version
- uses: actions/checkout@v4

# Bad: main ブランチ
- uses: actions/checkout@main
```

### Secret Scanning

```yaml
- name: Scan for secrets
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: ${{ github.event.pull_request.base.sha }}
    head: ${{ github.event.pull_request.head.sha }}
```

## Checklist

### Workflow 設計時

- [ ] permissions は最小限か
- [ ] OIDC を使用しているか（可能な場合）
- [ ] Reusable Workflow で共通化されているか
- [ ] キャッシュは適切に設定されているか
- [ ] concurrency group は設定されているか
- [ ] 本番デプロイに承認フローがあるか

### セキュリティ

- [ ] Secrets は環境ごとに分離されているか
- [ ] Branch protection rules が設定されているか
- [ ] CODEOWNERS が設定されているか
