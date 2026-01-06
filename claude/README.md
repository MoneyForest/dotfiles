# Claude Code Configuration

This directory contains Claude Code configuration files managed as dotfiles.

## Directory Structure

```
claude/
├── README.md           # This file
├── settings.json       # Main configuration file (symlinked to ~/.claude/settings.json)
├── CLAUDE.md          # Overview and reference to modular rules
├── rules/             # Modular rule files (symlinked to ~/.claude/rules)
├── hooks/             # Session hooks (symlinked to ~/.claude/hooks)
└── commands/          # Custom commands (symlinked to ~/.claude/commands)
```

## MCP Servers

MCP (Model Context Protocol) servers are configured in `settings.json` under the `mcpServers` section.

### Pre-configured MCP Servers

The following MCP servers are pre-configured and require no authentication:

- **terraform-mcp-server**: Terraform provider documentation and resource lookup
- **aws-knowledge-mcp-server**: AWS documentation search and regional availability
- **memory**: Knowledge graph for conversation memory
- **sequential-thinking**: Chain-of-thought reasoning support
- **playwright**: Browser automation for web scraping
- **context7**: Up-to-date library documentation

These servers will automatically work after running `bin/install.sh` and restarting Claude Code.

### Optional MCP Servers (Requires Authentication)

#### GitHub MCP Server

To enable GitHub MCP server, add to `~/.zsh_private`:

```bash
export GITHUB_PAT="your_github_personal_access_token"
```

Then add to `claude/settings.json`:

```json
{
  "mcpServers": {
    "github": {
      "url": "https://api.githubcopilot.com/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer ${GITHUB_PAT}"
      }
    }
  }
}
```

**Creating a GitHub Personal Access Token:**
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Copy the token and add to `~/.zsh_private`

#### Datadog MCP Server

To enable Datadog MCP server, add to `~/.zsh_private`:

```bash
export DD_API_KEY="your_datadog_api_key"
export DD_APPLICATION_KEY="your_datadog_application_key"
```

Then add to `claude/settings.json`:

```json
{
  "mcpServers": {
    "datadog-mcp": {
      "url": "https://mcp.datadoghq.com/api/unstable/mcp-server/mcp",
      "transport": "http",
      "headers": {
        "DD_API_KEY": "${DD_API_KEY}",
        "DD_APPLICATION_KEY": "${DD_APPLICATION_KEY}"
      }
    }
  }
}
```

**Note:** Datadog MCP also supports OAuth 2.0 authentication. If you prefer browser-based authentication, omit the `headers` section.

## Permissions

The `permissions` section in `settings.json` controls which operations Claude Code can perform:

- **allow**: Commands that can run without user confirmation
- **deny**: Commands that always require user confirmation or are blocked

See `settings.json` for the full list of allowed and denied operations.

## Hooks

### SessionStart Hook

The `SessionStart` hook runs at the beginning of each Claude Code session:

- Runs `~/.claude/hooks/init-session.sh`
- Checks for repository-specific `CLAUDE.md` file
- Verifies permission settings

## Rules

Project-specific instructions are organized in the `rules/` directory:

- `00-session-init.md` - Session initialization requirements
- `communication.md` - Communication language and fact-based operations
- `git-commit.md` - Git commit message guidelines
- `terraform.md` - Terraform coding standards (applies to `terraform/**/*.tf`)
- `github-actions.md` - GitHub Actions workflow architecture (applies to `.github/workflows/**/*.yml`)
- `dev-tools.md` - Development tools and utilities

Rules with `paths` frontmatter are conditionally applied based on the files being edited.

## Installation

Run the installation script to set up symlinks:

```bash
./bin/install.sh
```

This will:
1. Create `~/.claude/` directory
2. Symlink `settings.json`, `CLAUDE.md`, `rules/`, `hooks/`, and `commands/`
3. Install Node.js (required for MCP servers)
4. Display MCP server configuration status

## Troubleshooting

### MCP Servers Not Working

1. **Check Node.js installation:**
   ```bash
   node --version
   ```
   MCP servers require Node.js to run.

2. **Restart Claude Code:**
   Settings changes require a restart to take effect.

3. **Check MCP server logs:**
   Claude Code logs MCP server errors to the console.

### Environment Variables Not Loading

Ensure `~/.zsh_private` is sourced in your `~/.zshrc`:

```bash
# In ~/.zshrc
[ -f ~/.zsh_private ] && source ~/.zsh_private
```

## References

- [Claude Code Documentation](https://code.claude.com/docs)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
