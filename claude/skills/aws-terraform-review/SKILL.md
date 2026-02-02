---
name: aws-terraform-review
description: AWS infrastructure change review checklist for Terraform including blast radius assessment, security validation, and rollback planning. Use when reviewing Terraform PRs, planning AWS changes, or assessing infrastructure modifications. Trigger phrases: 'terraform review', 'aws review', 'infrastructure review', 'Terraformレビュー', 'インフラレビュー', '変更確認'.
metadata:
  author: MoneyForest
  version: 1.0.0
  category: review
  tags: [terraform, aws, code-review, infrastructure, security]
---

# AWS Infrastructure Review Checklist

AWS インフラ変更レビュー時の確認観点。`fact-check` は状態確認、このスキルはレビュー観点を提供する。

> **Note**: このスキルは AWS + Terraform + GitHub Actions に特化しています。

## When to Activate

- Terraform PR レビュー
- AWS リソース変更の確認
- GitHub Actions 変更のレビュー
- インフラ変更の承認前

## Terraform Change Review

### 1. Destructive Changes

`terraform plan` 出力で以下を確認：

```text
# 破壊的変更の検出
- destroy          # リソース削除
- replace          # リソース再作成（= 削除 + 作成）
- forces replacement  # 変更により再作成が発生
```

### 確認事項

| 変更タイプ | 確認観点 |
|-----------|---------|
| `destroy` | 本当に削除してよいか、依存リソースへの影響 |
| `replace` | ダウンタイムの有無、データ消失の有無 |
| `update in-place` | 通常は安全、ただし設定変更の影響を確認 |

### 2. Security Impact

```text
# 確認すべき変更
- [ ] Security Group の ingress/egress ルール
- [ ] IAM Policy の Action/Resource
- [ ] S3 Bucket の public access 設定
- [ ] RDS の publicly_accessible
- [ ] KMS Key policy
```

### Security Group 変更

```hcl
# 危険: 0.0.0.0/0 からの許可
resource "aws_vpc_security_group_ingress_rule" "bad" {
  cidr_ipv4 = "0.0.0.0/0"  # 要確認
  from_port = 22           # SSH は特に危険
}
```

### IAM Policy 変更

```hcl
# 危険: ワイルドカードの使用
data "aws_iam_policy_document" "bad" {
  statement {
    actions   = ["s3:*"]  # 過剰な権限
    resources = ["*"]     # 全リソース
  }
}
```

### 3. Cost Impact

```text
# コストに影響する変更
- [ ] インスタンスタイプの変更（CPU, Memory）
- [ ] ストレージサイズの増加
- [ ] NAT Gateway の追加
- [ ] RDS Multi-AZ の有効化
- [ ] Reserved Instance の変更
```

### コスト見積もり

```bash
# infracost を使用（推奨）
infracost breakdown --path .
infracost diff --path . --compare-to infracost-base.json
```

### 4. State Manipulation

```text
# 危険な State 操作
- terraform state rm   # リソースを State から削除（実リソースは残る）
- terraform state mv   # リソースアドレスの変更
- terraform import     # 既存リソースの取り込み
```

## AWS Resource Review

### ECS Changes

| 変更 | 確認観点 |
|------|---------|
| Task Definition | コンテナイメージ、環境変数、シークレット |
| Service | desired_count、デプロイメント設定 |
| Cluster | キャパシティプロバイダー設定 |

```bash
# 変更前後の確認
aws ecs describe-task-definition --task-definition <name> --query 'taskDefinition'
```

### RDS Changes

| 変更 | 影響 | 確認観点 |
|------|------|---------|
| instance_class | ダウンタイム可能性 | メンテナンスウィンドウ |
| engine_version | 再起動 | 互換性、バックアップ |
| storage | オンライン拡張可能 | IOPS への影響 |
| multi_az | フェイルオーバー | 切り替え時間 |

### IAM Changes

```text
# 影響範囲の確認
- [ ] このロールを使用しているサービス/ユーザー
- [ ] Trust Policy の変更は誰がこのロールを使えるかを変える
- [ ] Permission Policy の変更は何ができるかを変える
```

```bash
# ロールを使用しているリソースの確認
aws iam get-role --role-name <role> --query 'Role.AssumeRolePolicyDocument'
aws iam list-attached-role-policies --role-name <role>
```

### Network Changes

| 変更 | 確認観点 |
|------|---------|
| VPC CIDR | 既存サブネットとの重複 |
| Subnet | ルートテーブル関連付け |
| Security Group | 影響を受けるリソース |
| Route Table | トラフィックフローの変更 |
| NAT Gateway | コスト、可用性 |

## GitHub Actions Review

### 1. Secrets Usage

```yaml
# 確認事項
- [ ] Secrets は環境ごとに分離されているか
- [ ] OIDC を使用できる場面で長期クレデンシャルを使っていないか
- [ ] Secrets がログに出力されていないか
```

```yaml
# 危険: Secrets のログ出力
- run: echo "Key is ${{ secrets.API_KEY }}"  # NG

# 安全: 環境変数として渡す
- run: ./script.sh
  env:
    API_KEY: ${{ secrets.API_KEY }}
```

### 2. Permissions Scope

```yaml
# デフォルト権限は最小限であるべき
permissions: {}  # デフォルト

jobs:
  build:
    permissions:
      contents: read      # 必要なものだけ
      packages: write     # 明示的に付与
```

| 権限 | 使用場面 |
|------|---------|
| `contents: read` | コードのチェックアウト |
| `contents: write` | タグ作成、リリース |
| `id-token: write` | OIDC 認証 |
| `pull-requests: write` | PR コメント |
| `packages: write` | Container Registry |

### 3. Third-Party Actions

```yaml
# 確認事項
- [ ] メジャーバージョンまたは SHA でピン留めされているか
- [ ] 信頼できるソースか（公式、verified creator）
- [ ] 必要な権限は最小限か
```

```yaml
# Good
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
- uses: actions/checkout@v4

# Bad
- uses: actions/checkout@main  # 危険
- uses: unknown-user/some-action@v1  # 要確認
```

### 4. Workflow Triggers

```yaml
# 確認事項
- [ ] pull_request_target を使用している場合、フォークからの実行リスク
- [ ] workflow_dispatch の入力バリデーション
- [ ] push トリガーのブランチ制限
```

```yaml
# 危険: フォークからの PR で Secrets にアクセス可能
on:
  pull_request_target:
    types: [opened]

# 安全: pull_request を使用
on:
  pull_request:
    types: [opened]
```

## Review Checklist Template

### Terraform PR

```markdown
## レビューチェックリスト

### 破壊的変更
- [ ] `terraform plan` で destroy/replace を確認
- [ ] ダウンタイムの影響を評価
- [ ] データ消失の可能性を確認

### セキュリティ
- [ ] Security Group の変更を確認
- [ ] IAM Policy の変更を確認
- [ ] 機密情報がコードに含まれていないか

### コスト
- [ ] リソースサイズ変更の影響
- [ ] 新規リソースのコスト見積もり

### 依存関係
- [ ] State の依存関係を確認
- [ ] 他環境への影響を確認
```

### GitHub Actions PR

```markdown
## レビューチェックリスト

### セキュリティ
- [ ] permissions は最小限か
- [ ] Secrets の使用は適切か
- [ ] サードパーティ Actions のバージョン固定

### 構造
- [ ] 3層アーキテクチャに準拠しているか
- [ ] Reusable Workflow で共通化されているか

### 機能
- [ ] テストジョブが含まれているか
- [ ] 失敗時の通知が設定されているか
```

## Quick Commands

```bash
# Terraform plan の確認
terraform plan -detailed-exitcode

# 変更されるリソースの一覧
terraform plan -out=tfplan && terraform show -json tfplan | jq '.resource_changes[] | {address, actions}'

# Security Group の確認
aws ec2 describe-security-groups --group-ids <sg-id> --query 'SecurityGroups[0].IpPermissions'

# IAM Role の確認
aws iam get-role --role-name <role> --query 'Role.AssumeRolePolicyDocument'
aws iam list-attached-role-policies --role-name <role>

# ECS Task Definition の比較
diff <(aws ecs describe-task-definition --task-definition <old>) \
     <(aws ecs describe-task-definition --task-definition <new>)
```

## Approval Criteria

### Must Block

- セキュリティグループで 0.0.0.0/0 への不要な開放
- IAM ポリシーでの過剰な権限（`*:*`）
- 機密情報のハードコード
- 本番環境のデータ削除を伴う変更（意図しない場合）
- GitHub Actions での Secrets の不適切な露出

### Should Discuss

- インスタンスタイプの大幅な変更（コスト影響）
- ネットワーク構成の変更
- 暗号化設定の変更
- バックアップ/リテンション設定の変更
