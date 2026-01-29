---
name: fact-check
description: Verify facts from Datadog and AWS before making changes. Use when investigating infrastructure state, validating user claims, or before modifying resources.
---

# Fact-Check Skill

ユーザーの指示を鵜呑みにせず、実際の状態を確認してから作業する。

## 確認の優先順位

1. **Datadog** - モニター、ダッシュボード、メトリクス
2. **Terraform State** - 管理されているリソースの現在値
3. **AWS API** - 実際のリソース状態

## Step 1: Datadog確認

Datadog APIキーをSSMから取得して確認する。

```bash
# APIキー取得（bsize-operation）
DD_API_KEY=$(aws-vault exec bsize-operation -- aws ssm get-parameter \
  --name "/datadog/terraform/api_key" --with-decryption \
  --query "Parameter.Value" --output text)
DD_APP_KEY=$(aws-vault exec bsize-operation -- aws ssm get-parameter \
  --name "/datadog/terraform/app_key" --with-decryption \
  --query "Parameter.Value" --output text)

# モニター確認
curl -s "https://api.datadoghq.com/api/v1/monitor/<monitor_id>" \
  -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq

# モニター検索（名前で）
curl -s "https://api.datadoghq.com/api/v1/monitor?name=<search_term>" \
  -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq

# ダッシュボード一覧
curl -s "https://api.datadoghq.com/api/v1/dashboard" \
  -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" | jq '.dashboards[] | {id, title}'
```

## Step 2: Terraform State確認

対象環境のTerraform stateを確認する。

```bash
# プロファイル選択
# - bsize-dev: bsize_bot_dev, bsize_drive_dev
# - bsize-prd: bsize_bot_prd, bsize_drive_prd
# - bsize-operation: bsize_operation, bsize_payer, datadog

# リソース一覧
cd terraform/<provider>/<environment>
aws-vault exec <profile> -- terraform state list | grep <keyword>

# リソース詳細
aws-vault exec <profile> -- terraform state show <resource_address>
```

### 環境とプロファイルの対応

| 環境 | aws-vault profile | パス |
|------|-------------------|------|
| bsize_bot_dev | bsize-bot-dev | terraform/aws/bsize_bot_dev/ |
| bsize_bot_prd | bsize-bot-prd | terraform/aws/bsize_bot_prd/ |
| bsize_drive_dev | bsize-drive-dev | terraform/aws/bsize_drive_dev/ |
| bsize_drive_stg | bsize-drive-stg | terraform/aws/bsize_drive_stg/ |
| bsize_drive_prd | bsize-drive-prd | terraform/aws/bsize_drive_prd/ |
| bsize_operation | bsize-operation | terraform/aws/bsize_operation/ |
| bsize_payer | bsize-payer | terraform/aws/bsize_payer/ |
| bsize_poc | bsize-poc | terraform/aws/bsize_poc/ |
| datadog | bsize-operation | terraform/datadog/bsize/ |
| gcp_bot_dev | (gcloud) | terraform/gcp/bsize_bot_dev/ |
| gcp_bot_prd | (gcloud) | terraform/gcp/bsize_bot_prd/ |

## Step 3: AWS API確認

Terraform stateで不足する情報をAWS APIで補完する。

```bash
# ECS
aws-vault exec <profile> -- aws ecs describe-services \
  --cluster <cluster> --services <service> --query "services[0]"

aws-vault exec <profile> -- aws ecs describe-task-definition \
  --task-definition <task-def> --query "taskDefinition"

# RDS
aws-vault exec <profile> -- aws rds describe-db-clusters \
  --db-cluster-identifier <cluster-id>

aws-vault exec <profile> -- aws rds describe-db-instances \
  --db-instance-identifier <instance-id>

# Lambda
aws-vault exec <profile> -- aws lambda get-function \
  --function-name <function-name>

# CloudWatch Logs
aws-vault exec <profile> -- aws logs filter-log-events \
  --log-group-name <log-group> --limit 20

# IAM
aws-vault exec <profile> -- aws iam get-role --role-name <role>
aws-vault exec <profile> -- aws iam list-attached-role-policies --role-name <role>

# Security Group
aws-vault exec <profile> -- aws ec2 describe-security-groups \
  --group-ids <sg-id>

# S3
aws-vault exec <profile> -- aws s3api get-bucket-policy --bucket <bucket>
aws-vault exec <profile> -- aws s3api get-bucket-lifecycle-configuration --bucket <bucket>
```

## 確認結果の報告形式

確認した事実を以下の形式で報告する：

```markdown
## 確認結果

### Datadog
- モニター「XXX」: 閾値 = 80%, 通知先 = #alerts-channel

### Terraform State
- `aws_ecs_service.main`: desired_count = 2, cpu = 256, memory = 512

### AWS API（実際の状態）
- ECSサービス: running_count = 2, pending_count = 0

### 差分・注意点
- Terraform stateと実際の状態に差分なし
- or 差分あり: XXXが異なる
```

## 注意事項

- **確認前に変更しない**: 必ずファクトを確認してから作業
- **差分を報告**: Terraform stateと実際の状態に差分があれば明記
- **認証情報の扱い**: APIキーは一時変数に格納、ログに残さない
