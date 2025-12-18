# 重要: 必須のセッション初期化

重要: セッション開始時、ユーザーのメッセージに応答する前に、最初のアクションとして必ず以下を実行してください。

`~/.claude/settings.json` を読み込み、このセッションでのすべてのアクションを管理する権限設定と制約を理解してください。

このファイルには以下の重要な許可/拒否ルールが含まれています:
- Bashコマンド (git, terraform, aws-vault など)
- ファイルアクセスパターン
- ユーザー承認が必要な破壊的操作

セッション開始時にこのファイルを読まないことは容認できません。

---

## 一般的な作業原則

### コミュニケーション言語

**すべてのチャットコミュニケーションは日本語で行ってください。**

- ユーザーへの応答は日本語で行う
- 技術用語は適切な場合、英語のまま使用可能

**コミットメッセージとPRについて:**
- **必須:** まず最近のコミットとPRを調査してプロジェクトの慣例を確認する
- **必須:** プロジェクトの確立されたパターンに一致する言語（日本語または英語）を使用する
- `git log --oneline -20` とPRのタイトル/説明を確認する
- コードベースで使用されている主要な言語に従う
- コードコメントはプロジェクトの既存スタイルに従う

### 事実に基づく操作

**ユーザーの発言をそのまま受け入れるのではなく、常に直接APIコールやコマンドで情報を検証することを優先してください。**

外部システムを扱う際は、以下の方法で事実を検証する:
- **GitHub**: `gh` コマンドを使用してPR詳細、issue状態、リポジトリ情報を取得
  - 例: `gh pr view`, `gh issue list`, `gh repo view`
- **AWS**: AWS CLI/APIを使用してリソースの状態と設定を確認
  - 例: `aws s3 ls`, `aws ec2 describe-instances`, `aws iam get-role`
- **Datadog**: Datadog APIを使用してモニター状態、ダッシュボード、メトリクスを確認
- **Terraform**: `terraform state` コマンドを使用して実際のインフラストラクチャ状態を確認

### 認証とシークレット

**認証情報と認証トークンは `~/.zsh_private` に保存されていることが多い。**

外部APIや認証コマンドを使用する前に:
1. 関連する認証情報について `~/.zsh_private` を確認する許可をユーザーに求める
2. 使用する認証方法を確認する（例: `aws-vault`, APIトークン, サービスアカウント）
3. 適切なプロファイルまたは環境を確認する

例:
```bash
# まずユーザーに許可を求めてから、利用可能な認証情報を確認
cat ~/.zsh_private | grep -i "datadog\|aws\|github"
```

---

## Git/PRガイドライン

### コミットメッセージの哲学と優先順位

**最優先事項: 簡潔さと明確さ**
- **必須:** コミットメッセージテンプレートに厳密に従う
- **必須:** 冗長な表現を避け、簡潔かつ要点を押さえる
- **必須:** コミットメッセージをシンプルに保ち、必要不可欠な情報に集中する

**次点: コミットメッセージのベストプラクティス**
- 詳細なコミットメッセージルール（Seven Rules）は適切な場合に適用する
- 詳細な説明は本当に必要な場合のみ本文に記載する

**署名ポリシー**
- **禁止:** コミットメッセージに以下の署名を含めない:
  - `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
  - `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
- これらの署名は不要であり、コミット履歴にノイズを追加する

### コミットメッセージフォーマット

[Angular Commit Message Format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format) に従ってください。

### コミット/PRタイトル

```
<type>(<scope>): <summary>
```

| Type       | Description          |
| ---------- | -------------------- |
| `feat`     | 新機能               |
| `fix`      | バグ修正             |
| `docs`     | ドキュメントのみ     |
| `refactor` | コードリファクタリング |
| `chore`    | その他の変更         |

- **Scope**: 変更のターゲットスコープ（オプション）
  - **実行されたアクションではなく、影響を受ける領域に基づいて選択する**
  - 推奨されるスコープパターン:
    - アプリケーション層: `frontend`, `backend`, `api`
    - インフラ/DevOps: `infra`, `terraform`, `k8s`, `docker`
    - CI/CD: `ci`
    - 特定のサービス/コンポーネント: `datadog`, `aws`, `auth`, `database`
  - **スコープを省略する場合**:
    - ドキュメントのみの変更（スコープなしで`docs:`を使用）
    - プロジェクト全体に影響するdotfilesや設定変更
    - プロジェクト全体のガイドラインや規約の変更
    - 変更がプロジェクト全体に影響する場合
  - **避けるべきスコープパターン**:
    - アクションベース: `install`, `setup`, `update`, `config`, `scripts`
    - ディレクトリ名: `claude`, `bin`, `zsh`, `git`
    - 曖昧な名前: `tools`, `utils`, `misc`, `docs`
- **Summary**: シンプルな説明、末尾にピリオドなし

例:
- `feat(api): add user authentication`
- `fix(frontend): correct login form validation`
- `feat(ci): add automated testing workflow`
- `feat(terraform): add RDS cluster configuration`
- `docs: add setup instructions to README`
- `docs: clarify commit message priorities`
- `docs: update installation guide`

### プルリクエストの説明

Pull Requestテンプレート（`.github/pull_request_template.md`が存在する場合）に従い、簡潔で明確な説明を書く:

- 説明は簡潔に保ち、行われた変更に焦点を当てる
- プロジェクト固有のPRテンプレート構造に従う
- レビュワーに関連するコンテキストを含める
- 関連するissueをリンクする

---

## 良いコミットメッセージの書き方

### なぜ良いコミットメッセージを書くのか？

良いコミットメッセージを書く目的は:

- **実装者に聞かなくても `git-log` で変更理由が分かる**
  - 実装者が退職していたり、変更理由を忘れている場合の対策になる
  - Slackで変更理由を聞かれることが減る
- **変更内容を理解するために必要な時間が減る**
  - レビュワーの負担が減る
  - 必要なコードを誤って削除し、リグレッションが起きる可能性が減る

開発の持続可能性を高めるため、この文書では良いコミットメッセージの書き方を明確にします。

### ルールの対象範囲

このルールの対象は**「GitHubでデフォルトブランチにマージするコミット」**です。

それ以外のコミットは対象外なので、コミットメッセージを自由に書いて構いません:

- Draft Pull Requestのコミット
- ローカルリポジトリのコミット

これらはレビュー前にコミットメッセージを整えてください。

#### コミット粒度とコミットメッセージの哲学

koic氏の[TDD with git. Long live engineering.](https://speakerdeck.com/koic/tdd-with-git-long-live-engineering)が良い資料です。

### キーワード

各項目の必要条件を明確にするため、以下のキーワードを使用します:

- **MUST**（しなければなりません）: 対応する必要があります
- **SHOULD**（するべきです）: 推奨しますが、正当な理由があれば対応しなくても構いません
- **MAY**（してもよい）: 対応は任意です

### 優れたGitコミットメッセージの7つのルール

Chris Beamsの[How to Write a Git Commit Message](https://cbea.ms/git-commit/)に基づく:

1. **件名と本文を空行で区切る**
   - **必須:** 本文がある場合（3行目）、2行目は空行にする
   - `git log --oneline`, `git shortlog`, `git rebase`などのツールはこの区切りに依存している

2. **件名を50文字以内に制限する**
   - **推奨:** 件名は50文字以内に保つ
   - **必須:** 72文字をハードリミットとする
   - GitHubは72文字を超える件名を切り詰める

3. **件名の最初の文字を大文字にする**
   - **必須:** すべての件名は大文字で始める
   - 例: "Accelerate to 88 miles per hour" ではなく "accelerate to 88 miles per hour"

4. **件名の末尾にピリオドを付けない**
   - **必須:** 件名では末尾の句読点は不要
   - 50文字以内に保つためには、スペースは貴重

5. **件名では命令形を使用する**
   - **必須:** コマンドや指示を与えるように書く
   - 適切に形成されたGitコミット件名は次の文を完成させる: "If applied, this commit will _[your subject line]_"
   - 例: "Refactor subsystem X for readability" であり "Refactored subsystem X" ではない
   - Git自体も命令形を使用している（例: "Merge branch 'myfeature'"）

6. **本文を72文字で折り返す**
   - **推奨:** 本文のテキストを手動で72文字で折り返す
   - Gitは自動的にテキストを折り返さない
   - これにより、Gitがテキストをインデントしても、すべてが80文字以内に収まる

7. **本文では「何を」「なぜ」を説明し、「どのように」は説明しない**
   - **必須:** コードを変更した理由（Why）を記述する
   - **推奨:** 変更の理由を明確にすることに焦点を当てる - 以前は何が間違っていたか、今はどう動作するか、なぜその方法で解決したか
   - コードが「どのように」を説明する - 本文では「何を」と「なぜ」を説明する

### 追加のコミットメッセージガイドライン

1. **必須:** コミットメッセージは日本語または英語で記述する
1. **任意:** 軽微な変更（タイプミス修正など）の場合、1行のコミットメッセージでも可
1. **推奨:** コード例はスペース4個でインデントするか、マークダウン記法を使用する
1. **推奨:** マージ前に意味のある単位でコミットをスカッシュする
1. **推奨:** 各コミットは単位でリバート可能であるべき
1. **推奨:** パフォーマンス改善の場合、ベンチマーク結果をコミットメッセージに含める
1. **推奨:** GitHub URLを書く場合、タグまたはコミットSHAを含むURLを使用する（ブランチ名は不可）
   - 良い: `https://github.com/rails/rails/tree/v7.0.4.1/guides`
   - 良い: `https://github.com/rails/rails/tree/23e0345fe900dfd7edd6e8e5a7a6bd54b2a7d2ed/guides`
   - 悪い: `https://github.com/rails/rails/tree/main/guides`（mainブランチは変更される可能性がある）
1. **任意:** 必要に応じて以下のような追加情報を含めると良い:
     - 検証手順と実行結果
     - 検討したが不採用にした設計や実装案
     - Issue参照（例: "Resolves: #123", "See also: #456, #789"）
1. **任意:** 可読性のためにマークダウン記法を使用してもよい

### 良いコミットメッセージの例

#### 例1: シンプルな1行コミット
```
Fix typo in introduction to user guide
```

シンプルな変更の場合、1行で十分です。

#### 例2: 詳細な説明付きコミット
```
Summarize changes in around 50 characters or less

More detailed explanatory text, if necessary. Wrap it to about 72
characters or so. In some contexts, the first line is treated as the
subject of the commit and the rest of the text as the body. The
blank line separating the summary from the body is critical (unless
you omit the body entirely); various tools like `log`, `shortlog`
and `rebase` can get confused if you run the two together.

Explain the problem that this commit is solving. Focus on why you
are making this change as opposed to how (the code explains that).
Are there side effects or other unintuitive consequences of this
change? Here's the place to explain them.

Further paragraphs come after blank lines.

 - Bullet points are okay, too

 - Typically a hyphen or asterisk is used for the bullet, preceded
   by a single space, with blank lines in between, but conventions
   vary here

If you use an issue tracker, put references to them at the bottom,
like this:

Resolves: #123
See also: #456, #789
```

#### 例3: Bitcoin Coreからの実際の例
```
Simplify serialize.h's exception handling

Remove the 'state' and 'exceptmask' from serialize.h's stream
implementations, as well as related methods.

As exceptmask always included 'failbit', and setstate was always
called with bits = failbit, all it did was immediately raise an
exception. Get rid of those variables, and replace the setstate
with direct exception throwing (which also removes some dead
code).

As a result, good() is never reached after a failure (there are
only 2 calls, one of which is in tests), and can just be replaced
by !eof().

fail(), clear(n) and exceptions() are just never called. Delete
them.
```

#### 例4: コード例付き
```
Refactor user authentication for better maintainability

The previous authentication logic was scattered across multiple
controllers, making it difficult to maintain and test. This commit
centralizes authentication logic into a dedicated concern.

Code examples can be embedded by indenting with 4 spaces:

    class ArticlesController
      def index
        render json: Article.limit(10)
      end
    end

Or use markdown syntax:

\`\`\`ruby
class ArticlesController
  def index
    render json: Article.limit(10)
  end
end
\`\`\`

You can also add bullet points:

- Start bullet points with a dash (-) or asterisk (*)
- Wrap bullet lines at 72 characters, and indent additional
  lines with 2 spaces at the beginning for readability

References:
- https://github.com/rails/rails/tree/v7.0.4.1/guides
```

### これらの例が良い理由

1. **件名**: 明確、簡潔、命令形、50文字以内
2. **空行**: 件名と本文を区切る
3. **本文**: 「なぜ」と「何を」を説明し、「どのように」は説明しない
4. **コンテキスト**: 将来の開発者が推論を理解するのに十分な情報を含む
5. **参照**: 関連するissueやドキュメントへのリンクがある場合は含める

### コードレビュー運用ルール

開発者が良いコミットメッセージを書けるようにするため、コードレビューの運用ルールは以下の通りです:

1. **推奨:** レビュワーはコミットメッセージを読み、改善提案があればフィードバックする
2. **推奨:** レビューイーは改善提案にできるだけ対応する努力を行う
3. **任意:** 改善提案に対応するのが難しい場合、理由をコメントすることで対応しなくてもよい

### 参考資料

- [How to Write a Git Commit Message](https://cbea.ms/git-commit/)
- [Ruby on Rails Contributing Guide: Commit Your Changes](https://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#commit-your-changes)

---

## Terraformコーディングガイドライン

### ファイル命名規則

| ファイル名        | 目的                                       |
| ----------------- | ------------------------------------------ |
| `providers.tf`    | プロバイダー設定                           |
| `backend.tf`      | バックエンド設定                           |
| `terraform.tf`    | バージョン制約                             |
| `variables.tf`    | 入力変数                                   |
| `outputs.tf`      | 出力値                                     |
| `locals.tf`       | ローカル値                                 |
| `data.tf`         | データソース                               |
| `import.tf`       | Importブロック（apply後に削除）           |
| `moved.tf`        | Movedブロック（apply後に削除）            |
| `removed.tf`      | Removedブロック（apply後に削除）          |
| `<resource>.tf`   | 個別のリソース定義                         |

### リソース定義

- `main.tf`は使用しない
- リソースをタイプ/目的別に個別ファイルに分割する（例: `ecs_cluster.tf`, `s3_log.tf`）

### Variables vs Locals

**外部から渡す必要のない値には`locals.tf`を使用する。外部から設定可能である必要がある値のみ`variables.tf`を使用する。**

- **`variables.tf`**: 外部から渡す必要がある入力変数用（CLI、tfvarsファイル、またはモジュール呼び出し経由など）
- **`locals.tf`**: 内部値、計算値、または外部入力が不要な定数用

```hcl
# 悪い例: 内部専用の値にvariables.tfを使用
# variables.tf
variable "app_name" {
  default = "myapp"  # これは変更されず、外部から渡されない
}

# 良い例: 内部専用の値にはlocals.tfを使用
# locals.tf
locals {
  app_name = "myapp"
}

# 良い例: 外部入力が必要な場合のみvariables.tfを使用
# variables.tf
variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}
```

### リソースブロックの引数順序

[HashiCorp Style Guide](https://developer.hashicorp.com/terraform/language/style)に従う:

1. `count` / `for_each`
2. リソース固有の引数
3. ブロック引数
4. `lifecycle`
5. `depends_on`

### depends_on の使用

- **参照によって依存関係が解決される場合、`depends_on`を使用しない**
- Terraformは属性参照を通じて自動的に依存関係を解決する（例: `aws_s3_bucket.log.id`）
- `depends_on`は暗黙的な依存関係（参照が存在しない場合）にのみ使用する

```hcl
# 悪い例: バケット属性参照が存在するため、depends_onは冗長
resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
  depends_on = [aws_s3_bucket.log]  # 不要
}

# 良い例: 依存関係は参照を通じて自動的に解決される
resource "aws_s3_bucket_versioning" "log" {
  bucket = aws_s3_bucket.log.id
}
```

### セキュリティグループルールの定義

セキュリティグループルールには、インラインブロック（`ingress`/`egress`）ではなく**個別のリソース**を使用する。

以下の新しいリソースタイプを使用する:

- `aws_vpc_security_group_ingress_rule` - インバウンドルール
- `aws_vpc_security_group_egress_rule` - アウトバウンドルール

**注意**: 古い`aws_security_group_rule`は使用しない。

```hcl
# 悪い例: インラインブロック定義
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 良い例: 個別のリソース定義
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "example_https" {
  security_group_id = aws_security_group.example.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
```

### IAMポリシーの定義

**IAMのインラインポリシーを避け、`aws_iam_policy_document`データソースを使用して定義する:**

```hcl
# 悪い例: インラインポリシー（ハードコードされたJSON）
resource "aws_iam_role_policy" "example" {
  name = "example"
  role = aws_iam_role.example.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [...]
  })
}

# 良い例: aws_iam_policy_documentで定義
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

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}
```
