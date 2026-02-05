# JIRA Comment Skill

JIRAにコメントを投稿するスキル。一時ファイルの上書き事故を防止する。

## 使用方法

```
/jira-comment <ISSUE_KEY>
```

例: `/jira-comment PROJ-1234`

## 投稿手順

### 1. 認証情報の取得

- JIRA_EMAILとJIRA_API_KEYはJIRAプロジェクトによって異なるため、~/.zsh_privateなどを確認してユーザーに正しいか確認すること

```bash
JIRA_EMAIL=$(grep '^export JIRA_EMAIL=' ~/.zsh_private | sed 's/^export JIRA_EMAIL=//' | tr -d '"' | tr -d "'")
JIRA_KEY=$(grep '^export JIRA_API_KEY=' ~/.zsh_private | sed 's/^export JIRA_API_KEY=//' | tr -d '"' | tr -d "'")
```

### 2. 一時ファイル作成（重要：必ずmktempを使用）

```bash
# 毎回ユニークなファイル名を生成（上書き事故防止）
COMMENT_FILE=$(mktemp /tmp/jira_comment_XXXXXX.json)
echo "Created: $COMMENT_FILE"
```

### 3. ADF形式でコメント作成

```bash
cat > "$COMMENT_FILE" << 'EOFX'
{
  "body": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "heading",
        "attrs": {"level": 2},
        "content": [{"type": "text", "text": "見出し"}]
      },
      {
        "type": "paragraph",
        "content": [{"type": "text", "text": "本文テキスト"}]
      }
    ]
  }
}
EOFX
```

### 4. JSON検証（必須）

```bash
jq . "$COMMENT_FILE" > /dev/null && echo "✅ JSON valid" || echo "❌ JSON invalid"
```

### 5. 内容プレビュー（必須）

```bash
# 投稿前に内容を確認
jq -r '.body.content[] | if .type == "heading" then "## " + (.content[0].text // "") elif .type == "paragraph" then (.content[0].text // "") elif .type == "rule" then "---" elif .type == "bulletList" then (.content[] | "- " + (.content[0].content[0].text // "")) else .type end' "$COMMENT_FILE"
```

### 6. 投稿

- サブドメインはプロジェクトによって異なるためユーザーに確認すること。

```bash
curl -s -u "$JIRA_EMAIL:$JIRA_KEY" \
  -X POST -H "Content-Type: application/json" \
  -d @"$COMMENT_FILE" \
  "https://${subdomain}.atlassian.net/rest/api/3/issue/ISSUE_KEY/comment" | jq '{id, author: .author.displayName, created}'
```

### 7. クリーンアップ（必須）

```bash
rm -f "$COMMENT_FILE"
echo "Cleaned up: $COMMENT_FILE"
```

## ADF形式テンプレート

### 基本要素

```json
// 見出し（level: 1-6）
{"type": "heading", "attrs": {"level": 2}, "content": [{"type": "text", "text": "見出し"}]}

// 段落
{"type": "paragraph", "content": [{"type": "text", "text": "テキスト"}]}

// 太字
{"type": "paragraph", "content": [{"type": "text", "text": "太字", "marks": [{"type": "strong"}]}]}

// コード
{"type": "paragraph", "content": [{"type": "text", "text": "code", "marks": [{"type": "code"}]}]}

// 水平線
{"type": "rule"}

// 箇条書き
{
  "type": "bulletList",
  "content": [
    {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "項目1"}]}]},
    {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "項目2"}]}]}
  ]
}
```

### 注意事項

- **複数マークの組み合わせは避ける**（`[{"type": "code"}, {"type": "strong"}]` はエラーになる場合がある）
- 絵文字は直接テキストに含める（✅ ⚠️ ❓ など）
- テーブルは複雑なので箇条書きで代替推奨

## エラー対応

### INVALID_INPUT エラー

- ADF形式が不正
- marksの組み合わせが無効
- 対処: シンプルなADFに書き直す

### null レスポンス

- 認証エラーまたはIssueキーが不正
- `curl -v` で詳細確認
