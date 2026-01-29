# Git/PR Guidelines

## Commit Message Philosophy and Priorities

**Primary Priority: Conciseness and Clarity**
- **MUST:** Follow the commit message template strictly
- **MUST:** Avoid verbose expressions - be concise and to the point
- **MUST:** Keep commit messages simple and focused on essential information

**Secondary Priority: Commit Message Best Practices**
- Apply the detailed commit message rules (Seven Rules) when appropriate
- Use detailed explanations in the body only when truly necessary

**Signature Policy**
- **DO NOT** include the following signatures in commit messages:
  - `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
  - `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
- These signatures are unnecessary and add noise to commit history

## Commit Message Format

Follow the [Angular Commit Message Format](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format).

## Commit/PR Title

```
<type>(<scope>): <summary>
```

| Type       | Description                  |
| ---------- | ---------------------------- |
| `feat`     | New feature                  |
| `fix`      | Bug fix                      |
| `docs`     | Documentation only           |
| `refactor` | Code refactoring             |
| `chore`    | Other changes                |

- **Scope**: Target scope of the change (optional)
  - **Choose based on the affected area, not the action performed**
  - Recommended scope patterns:
    - Application layers: `frontend`, `backend`, `api`
    - Infrastructure/DevOps: `infra`, `terraform`, `k8s`, `docker`
    - CI/CD: `ci`
    - Specific services/components: `datadog`, `aws`, `auth`, `database`
  - **When to omit the scope**:
    - Documentation-only changes (use `docs:` without scope)
    - Dotfiles or configuration changes affecting the entire project
    - Changes to project-wide guidelines or conventions
    - When changes affect the entire project
  - **Avoid these scope patterns**:
    - Action-based: `install`, `setup`, `update`, `config`, `scripts`
    - Directory names: `claude`, `bin`, `zsh`, `git`
    - Vague names: `tools`, `utils`, `misc`, `docs`
- **Summary**: Simple description, no trailing period

Examples:
- `feat(api): add user authentication`
- `fix(frontend): correct login form validation`
- `feat(ci): add automated testing workflow`
- `feat(terraform): add RDS cluster configuration`
- `docs: add setup instructions to README`
- `docs: clarify commit message priorities`
- `docs: update installation guide`

## Pull Request Description

Write PR descriptions following the Pull Request Template (`.github/pull_request_template.md` if it exists) with concise, clear explanations:

- Keep descriptions brief and focused on the changes made
- Follow any project-specific PR template structure
- Include relevant context for reviewers
- Link related issues when applicable

---

## Writing Good Commit Messages

### Why Write Good Commit Messages?

The purpose of writing good commit messages is:

- **Understand change reasons via `git-log` without asking the implementer**
  - Protects against cases where the implementer has left the company or forgotten the reason for changes
  - Reduces questions about change reasons on Slack
- **Reduces time needed to understand changes**
  - Reduces reviewer burden
  - Reduces the possibility of accidentally deleting necessary code and causing regressions

To improve development sustainability, this document clarifies how to write good commit messages.

### Scope of Rules

These rules apply to **"commits merged to the default branch on GitHub"**.

Other commits are out of scope, so you can write commit messages freely:

- Commits in Draft Pull Requests
- Commits in local repositories

Please refine commit messages for these before review.

#### Commit Granularity and Commit Message Philosophy

Koichi Sasada's presentation [TDD with git. Long live engineering.](https://speakerdeck.com/koic/tdd-with-git-long-live-engineering) is an excellent resource.

### Keywords

To clarify the requirements for each item, the following keywords are used:

- **MUST**: Required to comply
- **SHOULD**: Recommended, but acceptable not to comply if there's a valid reason
- **MAY**: Optional to comply

### The Seven Rules of a Great Git Commit Message

Based on [How to Write a Git Commit Message](https://cbea.ms/git-commit/) by Chris Beams:

1. **Separate subject from body with a blank line**
  - **MUST:** If there's a body (third line), the second line must be blank
  - Tools like `git log --oneline`, `git shortlog`, and `git rebase` rely on this separation

2. **Limit the subject line to 50 characters**
  - **SHOULD:** Keep subject lines under 50 characters
  - **MUST:** Consider 72 characters the hard limit
  - GitHub will truncate subject lines longer than 72 characters

3. **Capitalize the subject line**
  - **MUST:** Begin all subject lines with a capital letter
  - Example: "Accelerate to 88 miles per hour" not "accelerate to 88 miles per hour"

4. **Do not end the subject line with a period**
  - **MUST:** Trailing punctuation is unnecessary in subject lines
  - Space is precious when keeping them under 50 characters

5. **Use the imperative mood in the subject line**
  - **MUST:** Write as if giving a command or instruction
  - A properly formed Git commit subject line should complete: "If applied, this commit will _[your subject line]_"
  - Examples: "Refactor subsystem X for readability" not "Refactored subsystem X"
  - Git itself uses imperative mood (e.g., "Merge branch 'myfeature'")

6. **Wrap the body at 72 characters**
  - **SHOULD:** Manually wrap body text at 72 characters
  - Git never wraps text automatically
  - This allows Git to indent text while keeping everything under 80 characters

7. **Use the body to explain what and why vs. how**
  - **MUST:** Describe the reason (Why) for changing the code
  - **SHOULD:** Focus on making clear the reasons for the change - what was wrong before, how it works now, and why you solved it this way
  - The code explains the "how" - use the body for "what" and "why"

### Additional Commit Message Guidelines

1. **MUST:** Write commit messages in Japanese or English
1. **MAY:** For minor changes (e.g., typo fixes), a one-line commit message is acceptable
1. **SHOULD:** Indent code examples with 4 spaces or use markdown syntax
1. **SHOULD:** Squash commits into meaningful units before merging
1. **SHOULD:** Each commit should be revertable as a unit
1. **SHOULD:** For performance improvements, include benchmark results in the commit message
1. **SHOULD:** When writing GitHub URLs, use URLs with tags or commit SHAs (not branch names)
  - Good: `https://github.com/rails/rails/tree/v7.0.4.1/guides`
  - Good: `https://github.com/rails/rails/tree/23e0345fe900dfd7edd6e8e5a7a6bd54b2a7d2ed/guides`
  - Bad: `https://github.com/rails/rails/tree/main/guides` (main branch can change)
1. **MAY:** Include additional helpful information:
    - Verification procedures and execution results
    - Alternative designs or implementations that were considered but not adopted
    - Issue references (e.g., "Resolves: #123", "See also: #456, #789")
1. **MAY:** Use markdown syntax for readability

### Good Commit Message Examples

#### Example 1: Simple one-line commit
```
Fix typo in introduction to user guide
```

For simple changes, a single line is sufficient.

#### Example 2: Commit with detailed explanation
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

#### Example 3: Real-world example from Bitcoin Core
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

#### Example 4: With code examples
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

### What Makes These Examples Good

1. **Subject line**: Clear, concise, imperative mood, under 50 characters
2. **Blank line**: Separates subject from body
3. **Body**: Explains the "why" and "what", not the "how"
4. **Context**: Includes enough information that future developers can understand the reasoning
5. **References**: Links to related issues or documentation when relevant

### Code Review Operation Rules

To help developers write good commit messages, the code review operation rules are:

1. **SHOULD:** Reviewers should read commit messages and provide feedback if they have improvement suggestions
2. **SHOULD:** Reviewees should make efforts to address improvement suggestions as much as possible
3. **MAY:** If it's difficult to address improvement suggestions, you may skip them by commenting with a reason

### References

- [How to Write a Git Commit Message](https://cbea.ms/git-commit/)
- [Ruby on Rails Contributing Guide: Commit Your Changes](https://guides.rubyonrails.org/contributing_to_ruby_on_rails.html#commit-your-changes)
