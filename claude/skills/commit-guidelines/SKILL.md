---
name: commit-guidelines
description: Detailed commit message guidelines with Angular format, Seven Rules, and practical examples. Use when writing commits, reviewing PR titles, or learning commit message best practices. Trigger phrases: 'commit message', 'git commit', 'commit format', 'angular commit', 'コミットメッセージ', 'コミット規約'.
metadata:
  author: MoneyForest
  version: 1.0.0
  category: documentation
  tags: [git, commit, conventions, documentation, best-practices]
---

# Commit Message Guidelines

詳細なコミットメッセージのガイドラインと例。

## When to Activate

- コミットメッセージの書き方を確認したい時
- PR タイトル/説明を書く時
- コードレビューでコミットメッセージを確認する時

## The Seven Rules of a Great Git Commit Message

Based on [How to Write a Git Commit Message](https://cbea.ms/git-commit/) by Chris Beams:

### 1. Separate subject from body with a blank line

- **MUST:** If there's a body, the second line must be blank
- Tools like `git log --oneline`, `git shortlog`, and `git rebase` rely on this

### 2. Limit the subject line to 50 characters

- **SHOULD:** Keep under 50 characters
- **MUST:** Never exceed 72 characters (GitHub truncates)

### 3. Capitalize the subject line

- **MUST:** Begin with a capital letter
- Example: "Accelerate to 88 miles per hour" not "accelerate to 88 miles per hour"

### 4. Do not end the subject line with a period

- **MUST:** No trailing punctuation

### 5. Use the imperative mood in the subject line

- **MUST:** Write as if giving a command
- Test: "If applied, this commit will _[your subject line]_"
- Good: "Refactor subsystem X for readability"
- Bad: "Refactored subsystem X"

### 6. Wrap the body at 72 characters

- **SHOULD:** Manually wrap at 72 characters
- Git never wraps text automatically

### 7. Use the body to explain what and why vs. how

- **MUST:** Describe the reason (Why) for changing the code
- The code explains the "how" - use the body for "what" and "why"

## Scope Guidelines

### Recommended Scopes

| Category | Examples |
|----------|----------|
| Application layers | `frontend`, `backend`, `api` |
| Infrastructure | `infra`, `terraform`, `k8s`, `docker` |
| CI/CD | `ci` |
| Services | `datadog`, `aws`, `auth`, `database` |

### When to Omit Scope

- Documentation-only changes: `docs: update README`
- Project-wide changes
- Dotfiles or configuration affecting entire project

### Avoid These Scopes

- Action-based: `install`, `setup`, `update`, `config`
- Directory names: `claude`, `bin`, `zsh`, `git`
- Vague: `tools`, `utils`, `misc`

## Good Commit Message Examples

### Example 1: Simple one-line

```
Fix typo in introduction to user guide
```

For simple changes, a single line is sufficient.

### Example 2: With detailed explanation

```
Summarize changes in around 50 characters or less

More detailed explanatory text, if necessary. Wrap it to about 72
characters or so. The blank line separating the summary from the
body is critical.

Explain the problem that this commit is solving. Focus on why you
are making this change as opposed to how (the code explains that).

- Bullet points are okay, too
- Use hyphen or asterisk for bullets

Resolves: #123
See also: #456, #789
```

### Example 3: Real-world (Bitcoin Core)

```
Simplify serialize.h's exception handling

Remove the 'state' and 'exceptmask' from serialize.h's stream
implementations, as well as related methods.

As exceptmask always included 'failbit', and setstate was always
called with bits = failbit, all it did was immediately raise an
exception. Get rid of those variables, and replace the setstate
with direct exception throwing (which also removes some dead code).

As a result, good() is never reached after a failure (there are
only 2 calls, one of which is in tests), and can just be replaced
by !eof().
```

### Example 4: With code examples

```
Refactor user authentication for better maintainability

The previous authentication logic was scattered across multiple
controllers. This commit centralizes it into a dedicated concern.

Code examples can be embedded:

    class ArticlesController
      def index
        render json: Article.limit(10)
      end
    end

References:
- https://github.com/rails/rails/tree/v7.0.4.1/guides
```

## Additional Guidelines

| Rule | Level | Description |
|------|-------|-------------|
| Language | MUST | Japanese or English (match project convention) |
| Minor changes | MAY | One-line message is acceptable |
| Code examples | SHOULD | Indent with 4 spaces or use markdown |
| Squash commits | SHOULD | Meaningful units before merging |
| Revertable | SHOULD | Each commit should be revertable as a unit |
| Performance | SHOULD | Include benchmark results for perf improvements |
| GitHub URLs | SHOULD | Use tags/SHAs, not branch names |

## Pull Request Description

- Follow PR template (`.github/pull_request_template.md`) if exists
- Keep descriptions brief and focused
- Include relevant context for reviewers
- Link related issues

## Keywords

- **MUST**: Required to comply
- **SHOULD**: Recommended, but acceptable to skip with valid reason
- **MAY**: Optional

## References

- [How to Write a Git Commit Message](https://cbea.ms/git-commit/)
- [Angular Commit Message Format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format)
- [Ruby on Rails Contributing Guide](https://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#commit-your-changes)
