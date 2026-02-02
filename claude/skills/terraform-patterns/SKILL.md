---
name: terraform-patterns
description: Advanced Terraform design patterns including module composition, state management, testing strategies, and workspace organization. Use when designing reusable modules, managing complex state, or implementing infrastructure patterns. Trigger phrases: 'terraform modules', 'tf patterns', 'infrastructure as code', 'state management', 'Terraform設計', 'モジュール設計'.
metadata:
  author: MoneyForest
  version: 1.0.0
  category: infrastructure
  tags: [terraform, iac, modules, aws, design-patterns]
---

# Terraform Design Patterns

`rules/terraform.md` は命名・構文規約を定義。このスキルは設計パターンを提供する。

## When to Activate

- 環境分離戦略の検討
- State 管理方針の決定
- リファクタリング時
- コーディング規約の詳細確認

## Coding Conventions (Examples)

### Variables vs Locals

```hcl
# Bad: Using variables for internal-only values
variable "app_name" {
  default = "myapp"  # Never changes, not passed from outside
}

# Good: Use locals for internal values
locals {
  app_name = "myapp"
}

# Good: Use variables only for external input
variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}
```

### depends_on - Only for Implicit Dependencies

```hcl
# Bad: Redundant - dependency resolved through reference
resource "aws_s3_bucket_versioning" "log" {
  bucket     = aws_s3_bucket.log.id
  depends_on = [aws_s3_bucket.log]  # Unnecessary
}

# Good: Dependencies auto-resolved through reference
resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
}
```

### Security Group Rules - Separate Resources

```hcl
# Bad: Inline block
resource "aws_security_group" "example" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Good: Separate resource
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.example.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
```

### IAM Policy - Use Data Source

```hcl
# Bad: Inline JSON
resource "aws_iam_role_policy" "example" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [...]
  })
}

# Good: Use aws_iam_policy_document
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
```

## Directory Structure（推奨）

モジュールは極力使わず、各環境で直接リソースを定義する。

```text
terraform/
├── module/              # 最小限の共有モジュールのみ
│   ├── aws-github-oidc/       # GitHub OIDC 認証
│   ├── aws-datadog-integration/ # Datadog 統合
│   └── shared-config/         # 共有設定（locals）
├── aws/
│   ├── project_dev/     # 環境ごとに独立
│   │   ├── backend.tf
│   │   ├── providers.tf
│   │   ├── locals.tf
│   │   ├── ecs.tf       # 直接リソース定義
│   │   ├── rds.tf
│   │   └── s3.tf
│   ├── project_stg/
│   ├── project_prd/
│   └── project_operation/  # 運用環境（共有リソース）
├── datadog/
│   └── project/
└── gcp/
    └── project_dev/
```

### モジュールを使うべきケース（最小限）

| ユースケース | 理由 |
|-------------|------|
| GitHub OIDC 認証 | 複数環境で同じ設定が必要、設定ミス防止 |
| Datadog 統合 | 統合設定は複雑で共通化のメリット大 |
| 共有設定（shared-config） | locals の共有 |

### モジュールを使わないケース

```hcl
# Bad: ECS サービスをモジュール化
module "ecs_service" {
  source = "../modules/ecs-service"
  name   = "api"
}

# Good: 直接リソースを定義（環境差異に対応しやすい）
resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = local.api_desired_count

  # 環境固有の設定を直接記述
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
```

### コード重複 vs 柔軟性

**コード重複を許容する理由**:
- 環境ごとの差異に柔軟に対応できる
- モジュールの抽象化コストを回避
- 変更時の影響範囲が明確
- デバッグが容易

## Symlink-Based Pattern（大規模プロジェクト向け）

コード共有が必要な場合、モジュールではなく symlink を使用する。

```text
terraform/
├── base/                      # 共通リソース定義
│   ├── __backend.tf           # __ プレフィックス = 環境固有（リンクしない）
│   ├── __locals.tf
│   ├── __provider.tf
│   ├── __terraform.tf
│   ├── acm.tf                 # 共通リソース
│   ├── alb_backend.tf
│   ├── ecs_cluster.tf
│   └── rds.tf
├── environment/
│   ├── dev/
│   │   ├── __backend.tf       # 環境固有（リンクなし）
│   │   ├── __locals.tf        # 環境固有の値
│   │   ├── __provider.tf
│   │   ├── acm.link.tf → ../../base/acm.tf
│   │   ├── alb_backend.link.tf → ../../base/alb_backend.tf
│   │   └── ecs_cluster.link.tf → ../../base/ecs_cluster.tf
│   ├── stg/
│   └── prod/
└── modules/                   # 最小限のモジュール
```

### 命名規則

| パターン | 意味 |
|---------|------|
| `__*.tf` | 環境固有ファイル（リンクしない） |
| `*.link.tf` | base からの symlink |
| `*.tf` (base) | 共通リソース定義 |

### 環境差異の吸収方法

```hcl
# base/ecs_cluster.tf - 共通定義
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = local.container_insights_enabled ? "enabled" : "disabled"
  }
}

# environment/dev/__locals.tf - 環境固有値
locals {
  name_prefix                = "myapp-dev"
  container_insights_enabled = false  # dev は無効
}

# environment/prod/__locals.tf - 環境固有値
locals {
  name_prefix                = "myapp-prod"
  container_insights_enabled = true   # prod は有効
}
```

### Symlink 作成コマンド

```bash
# environment/dev/ で実行
ln -s ../../base/ecs_cluster.tf ecs_cluster.link.tf
ln -s ../../base/alb_backend.tf alb_backend.link.tf
```

### Directory vs Symlink vs Workspace vs Module

| 観点 | Directory | Symlink | Workspace | Module |
|------|-----------|---------|-----------|--------|
| DRY | コード重複あり | 共通コードを1箇所で管理 | 共通コードを1箇所で管理 | 共通コードを1箇所で管理 |
| State 分離 | 完全分離 | 完全分離 | 同一 backend 内で分離 | 呼び出し元に依存 |
| 環境差異 | ファイル直接編集 | locals で吸収 | `terraform.workspace` で分岐 | variables で吸収 |
| 可読性 | 最も明確 | 直接リソースが見える | 条件分岐が増える | module ブロック経由 |
| 安全性 | 最も安全 | 安全 | 誤操作リスクあり | 安全 |
| 適用範囲 | 環境単位 | ファイル単位 | 全体 | module 単位 |
| 運用コスト | 高（重複管理） | 中 | 低 | 中 |

**推奨度**: Directory > Symlink > Module >> Workspace

**Directory を選ぶケース**（推奨）:
- 環境ごとに独立性を重視
- 本番環境の安全性が最優先
- 環境差異が大きい

**Symlink を選ぶケース**:
- 環境間で大部分のリソースが同じ
- ファイル単位でリンクの有無を制御したい
- モジュールの抽象化オーバーヘッドを避けたい

**Workspace を避ける理由**:
- `terraform workspace select` の誤操作リスク
- 環境の切り替えが暗黙的
- State が同一 backend に混在
- 本番環境への誤 apply の可能性

## State Management

### Remote State Best Practices

```hcl
# backend.tf (Terraform 1.10+)
terraform {
  backend "s3" {
    bucket       = "mycompany-terraform-state"
    key          = "aws/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true  # S3 ネイティブロック（DynamoDB 不要）
  }
}
```

**Note**: Terraform 1.10 以降は `use_lockfile = true` で S3 ネイティブのファイルロックが使用可能。DynamoDB テーブルは不要。

### State Isolation Rules

| 環境 | State File | 理由 |
|------|-----------|------|
| dev | `aws/dev/terraform.tfstate` | 開発環境の独立性 |
| prd | `aws/prd/terraform.tfstate` | 本番環境の安全性 |
| shared | `aws/shared/terraform.tfstate` | 共有リソース管理 |

### 共有値の参照方法

#### 推奨: shared-config module

```hcl
# module/shared-config/outputs.tf
output "vpc_id" {
  value = "vpc-xxxxx"
}

output "private_subnet_ids" {
  value = ["subnet-aaa", "subnet-bbb"]
}

# aws/project_dev/shared.tf
module "shared_config" {
  source = "../../module/shared-config"
}

resource "aws_ecs_service" "main" {
  network_configuration {
    subnets = module.shared_config.private_subnet_ids
  }
}
```

#### 非推奨: terraform_remote_state

```hcl
# 非推奨: state 間参照は事故りやすい
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "mycompany-terraform-state"
    key    = "aws/shared/terraform.tfstate"
    region = "ap-northeast-1"
  }
}
```

**terraform_remote_state を避ける理由**:
- 参照先の state 変更が参照元に影響
- output の削除・変更で予期せぬエラー
- 循環参照のリスク
- plan 時に参照先 state へのアクセスが必要

## Resource Naming Conventions

### Pattern: `{project}-{env}-{resource}-{identifier}`

```hcl
locals {
  project = "myapp"
  env     = "dev"

  # 一貫した命名
  name_prefix = "${local.project}-${local.env}"
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"
}
```

## count vs for_each

### count: 単純な有無の制御

```hcl
# Feature flag として使用
variable "enable_nat_gateway" {
  type    = bool
  default = true
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0
  # ...
}
```

### for_each: コレクションの反復（推奨）

```hcl
# Map による明示的な識別子
locals {
  subnets = {
    public-a  = { cidr = "10.0.1.0/24", az = "ap-northeast-1a", public = true }
    public-c  = { cidr = "10.0.2.0/24", az = "ap-northeast-1c", public = true }
    private-a = { cidr = "10.0.11.0/24", az = "ap-northeast-1a", public = false }
  }
}

resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${local.name_prefix}-${each.key}"
  }
}

# 参照: aws_subnet.main["public-a"].id
```

### count vs for_each 選択基準

| 条件 | 推奨 | 理由 |
|------|------|------|
| on/off の切り替え | `count` | シンプル |
| 同種リソースの複数作成 | `for_each` | 削除時の安全性 |
| 順序に依存しない | `for_each` | インデックス変更の影響なし |

## Data Source Patterns

### Lookup Pattern

```hcl
# AMI の動的取得
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# 既存リソースの参照
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["${local.name_prefix}-vpc"]
  }
}
```

### Conditional Data Source

```hcl
# 既存リソースがある場合のみ参照
data "aws_ecs_cluster" "existing" {
  count        = var.create_cluster ? 0 : 1
  cluster_name = var.existing_cluster_name
}

locals {
  cluster_arn = var.create_cluster ? aws_ecs_cluster.main[0].arn : data.aws_ecs_cluster.existing[0].arn
}
```

## Import and Migration Patterns

### Import Block (Terraform 1.5+)

```hcl
# import.tf - apply 後に削除
import {
  to = aws_s3_bucket.existing
  id = "my-existing-bucket"
}

resource "aws_s3_bucket" "existing" {
  bucket = "my-existing-bucket"
}
```

### Moved Block

```hcl
# moved.tf - リファクタリング時
moved {
  from = aws_s3_bucket.log
  to   = aws_s3_bucket.logs
}

# 複数リソースの移動
moved {
  from = module.old_module.aws_ecs_service.main
  to   = module.new_module.aws_ecs_service.main
}
```

### Removed Block (Terraform 1.7+)

```hcl
# removed.tf - state から削除（実リソースは残す）
removed {
  from = aws_s3_bucket.legacy

  lifecycle {
    destroy = false  # 実リソースを削除しない
  }
}

# 実リソースも削除する場合
removed {
  from = aws_cloudwatch_log_group.old

  lifecycle {
    destroy = true  # 実リソースも削除
  }
}
```

**Note**: `terraform state rm` の代替。コードで管理でき、チームで共有可能。

## Anti-Patterns to Avoid

### 1. Over-Modularization

```hcl
# Bad: 1リソースだけのモジュール
module "bucket" {
  source = "../modules/s3-bucket"
  name   = "my-bucket"
}

# Good: 直接リソースを定義
resource "aws_s3_bucket" "main" {
  bucket = "my-bucket"
}
```

### 2. Implicit Dependencies without Reference

```hcl
# Bad: depends_on が必要なのに参照がない
resource "aws_ecs_service" "main" {
  # listener が必要だが参照していない
  # depends_on が必要
}

# Good: 参照による明示的な依存
resource "aws_ecs_service" "main" {
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn  # 明示的参照
  }
}
```

## Checklist Before Apply

- [ ] `terraform fmt` で整形済み
- [ ] `terraform validate` で構文確認済み
- [ ] `terraform plan` で意図した変更のみ
- [ ] 破壊的変更（destroy, replace）がないか確認
- [ ] State のバックアップ確認
- [ ] 環境（workspace/directory）が正しいか確認
