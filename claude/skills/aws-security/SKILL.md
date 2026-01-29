---
name: aws-security
description: AWS infrastructure security best practices with Terraform examples. Use when configuring IAM, Security Groups, S3, RDS, or any AWS security-related resources.
---

# AWS Security Best Practices (Terraform)

AWS インフラのセキュリティ設計パターンとチェックリスト。Terraform コード例を含む。

> **Note**: このスキルは AWS + Terraform に特化しています。

## When to Activate

- IAM ポリシー設計
- Security Group 設定
- S3 バケット作成
- RDS セキュリティ設定
- VPC 設計
- シークレット管理

## IAM Best Practices

### Principle of Least Privilege

```hcl
# Good: 最小権限
data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*",
    ]
  }
}

# Bad: 過剰な権限
data "aws_iam_policy_document" "bad" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]  # 全アクション
    resources = ["*"]     # 全リソース
  }
}
```

### IAM Role Trust Policy

```hcl
# ECS Task 用の Trust Policy
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # 条件による制限（推奨）
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
```

### Service-Linked Roles vs Custom Roles

| 用途 | 推奨 |
|------|------|
| AWS サービス間連携 | Service-Linked Role |
| アプリケーション固有 | Custom Role |
| 一時的な権限付与 | IAM Role + AssumeRole |

### IAM Boundaries

```hcl
# 開発者が作成できるロールの権限を制限
resource "aws_iam_policy" "developer_boundary" {
  name = "DeveloperPermissionBoundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*", "dynamodb:*", "lambda:*"]
        Resource = "*"
      },
      {
        Effect   = "Deny"
        Action   = ["iam:*", "organizations:*"]
        Resource = "*"
      }
    ]
  })
}
```

## Security Group Design

### Layer-Based Security

```hcl
# ALB Security Group
resource "aws_security_group" "alb" {
  name   = "${local.name_prefix}-alb"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ECS Security Group - ALB からのみ許可
resource "aws_security_group" "ecs" {
  name   = "${local.name_prefix}-ecs"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id  # SG 参照
}

# RDS Security Group - ECS からのみ許可
resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-rds"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs.id
}
```

### Egress Rules

```hcl
# Good: 必要な通信のみ許可
resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"  # 外部 API 呼び出し用
}
```

## S3 Security

### Default Secure Configuration

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "${local.name_prefix}-data"
}

# パブリックアクセス禁止
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# バージョニング
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### Bucket Policy Best Practices

```hcl
data "aws_iam_policy_document" "bucket_policy" {
  # HTTPS のみ許可
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
```

## RDS Security

### Secure RDS Configuration

```hcl
resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"

  # ネットワーク
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # 暗号化
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # 認証
  iam_database_authentication_enabled = true

  # バックアップ
  backup_retention_period = 30
  backup_window           = "03:00-04:00"

  # 削除保護
  deletion_protection = true

  # ログ
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}
```

### Parameter Group Security

```hcl
resource "aws_db_parameter_group" "main" {
  name   = "${local.name_prefix}-pg"
  family = "postgres15"

  # SSL 強制
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # ログ設定
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }
}
```

## Secrets Management

### Secrets Manager

```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.name_prefix}/db-password"
  recovery_window_in_days = 30
}

# ローテーション設定
resource "aws_secretsmanager_secret_rotation" "db_password" {
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn

  rotation_rules {
    automatically_after_days = 30
  }
}
```

### SSM Parameter Store

```hcl
# 機密情報は SecureString
resource "aws_ssm_parameter" "api_key" {
  name  = "/${local.name_prefix}/api-key"
  type  = "SecureString"
  value = var.api_key  # tfvars から渡す

  lifecycle {
    ignore_changes = [value]  # 手動更新を許可
  }
}

# 設定値は String
resource "aws_ssm_parameter" "config" {
  name  = "/${local.name_prefix}/config"
  type  = "String"
  value = jsonencode(local.config)
}
```

### ECS での Secrets 参照

```hcl
resource "aws_ecs_task_definition" "main" {
  # ...
  container_definitions = jsonencode([{
    name = "app"
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = aws_secretsmanager_secret.db_password.arn
      },
      {
        name      = "API_KEY"
        valueFrom = aws_ssm_parameter.api_key.arn
      }
    ]
  }])
}
```

## VPC Security

### Subnet Design

```text
VPC (10.0.0.0/16)
├── Public Subnets (NAT Gateway, ALB)
│   ├── 10.0.1.0/24 (AZ-a)
│   └── 10.0.2.0/24 (AZ-c)
├── Private Subnets (ECS, Lambda)
│   ├── 10.0.11.0/24 (AZ-a)
│   └── 10.0.12.0/24 (AZ-c)
└── Isolated Subnets (RDS)
    ├── 10.0.21.0/24 (AZ-a)
    └── 10.0.22.0/24 (AZ-c)
```

### VPC Flow Logs

```hcl
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
}
```

### VPC Endpoints（推奨）

```hcl
# S3 Gateway Endpoint - 無料
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.s3"
}

# ECR Interface Endpoints
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
}
```

## Logging & Monitoring

### CloudTrail

```hcl
resource "aws_cloudtrail" "main" {
  name                       = "${local.name_prefix}-trail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail      = true
  enable_log_file_validation = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}
```

### CloudWatch Alarms

```hcl
# Root アカウント使用のアラート
resource "aws_cloudwatch_metric_alarm" "root_usage" {
  alarm_name          = "${local.name_prefix}-root-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

## Security Checklist

### Before Deployment

- [ ] IAM ポリシーは最小権限か
- [ ] Security Group は必要なポートのみ開いているか
- [ ] S3 バケットはパブリックアクセスがブロックされているか
- [ ] RDS は `publicly_accessible = false` か
- [ ] シークレットは Secrets Manager/SSM に格納されているか
- [ ] 暗号化は有効になっているか（S3, RDS, EBS）
- [ ] VPC Flow Logs は有効か
- [ ] CloudTrail は有効か

### Periodic Review

- [ ] 未使用の IAM ユーザー/ロールの削除
- [ ] シークレットのローテーション
- [ ] Security Group ルールの見直し
- [ ] アクセスログの確認
