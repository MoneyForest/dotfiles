#!/bin/zsh

link_claude_settings() {
  local current_dir="$1"
  local claude_dir="$HOME/.claude"

  mkdir -p "$claude_dir"

  # Link Claude Code settings.json
  local claude_settings_src="$current_dir/claude/settings.json"
  local claude_settings_dest="$claude_dir/settings.json"

  if [ -f "$claude_settings_src" ]; then
    ln -sf "$claude_settings_src" "$claude_settings_dest" && info "Claude Code settings.json was linked" || warn "Failed to link Claude Code settings"
  else
    warn "Claude Code settings.json does not exist and was not linked"
  fi

  # Link Claude Code directories
  local directories=("hooks" "commands" "rules" "skills")

  for dir_name in "${directories[@]}"; do
    local src="$current_dir/claude/$dir_name"
    local dest="$claude_dir/$dir_name"

    if [ -d "$src" ]; then
      ln -sfn "$src" "$dest" && info "Claude Code $dir_name directory was linked" || warn "Failed to link Claude Code $dir_name"
    else
      warn "Claude Code $dir_name directory does not exist and was not linked"
    fi
  done
}

install_mcp_servers() {
  if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found. Install Claude Code to enable MCP server setup."
    return
  fi

  info "Installing Claude Code MCP servers..."

  # Define MCP servers to install (all use npx/uvx, all are authentication-free)
  # Note: WebFetch functionality is already built into Claude Code, so no separate fetch server needed
  # Note: aws-knowledge-mcp-server replaces aws-documentation-mcp-server with additional regional features
  # Note: aws-core-mcp-server should be installed first as it orchestrates other AWS MCP servers
  local mcp_servers=(
    "terraform-mcp-server|stdio|npx|-y terraform-mcp-server"
    "aws-knowledge-mcp-server|stdio|npx|mcp-remote https://knowledge-mcp.global.api.aws"
    "aws-core-mcp-server|stdio|uvx|awslabs.core-mcp-server@latest"
    "memory|stdio|npx|-y @modelcontextprotocol/server-memory"
    # "playwright|stdio|npx|-y @playwright/mcp"  # Browser automation (high context cost)
    "context7|stdio|npx|-y @upstash/context7-mcp"
  )

  for server_config in "${mcp_servers[@]}"; do
    IFS='|' read -r server_name transport command args <<< "$server_config"

    # Check if server already exists
    if claude mcp list 2>/dev/null | grep -q "^$server_name"; then
      info "MCP server '$server_name' already exists, skipping"
    else
      # Add MCP server - need to use eval to properly split args
      if eval "claude mcp add -s user -t '$transport' '$server_name' -- $command $args" 2>/dev/null; then
        info "Added MCP server: $server_name"
      else
        warn "Failed to add MCP server: $server_name"
      fi
    fi
  done

  # Install GitHub MCP server (requires authentication)
  _install_github_mcp

  # Install Datadog MCP server
  _install_datadog_mcp
}

_install_github_mcp() {
  # Note: GitHub MCP server requires a Personal Access Token (PAT)
  # Set GITHUB_PAT environment variable before running this script, or configure manually after installation
  if ! claude mcp list 2>/dev/null | grep -q "^github"; then
    if [ -n "$GITHUB_PAT" ]; then
      info "Installing GitHub MCP server with authentication..."
      if claude mcp add -s user --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer $GITHUB_PAT" 2>/dev/null; then
        info "Added GitHub MCP server"
      else
        warn "Failed to add GitHub MCP server. You may need to configure it manually."
      fi
    else
      warn "GITHUB_PAT environment variable not set. Skipping GitHub MCP server installation."
      warn "To install manually, run: claude mcp add -s user --transport http github https://api.githubcopilot.com/mcp -H \"Authorization: Bearer YOUR_GITHUB_PAT\""
    fi
  else
    info "GitHub MCP server already exists, skipping"
  fi
}

_install_datadog_mcp() {
  # Note: Uses OAuth 2.0 for authentication (requires browser sign-in on first use)
  # Alternatively, set DD_API_KEY and DD_APPLICATION_KEY environment variables for API key authentication
  if ! claude mcp list 2>/dev/null | grep -q "^datadog-mcp"; then
    info "Installing Datadog MCP server..."

    # Check if API key authentication is preferred (via environment variables)
    if [ -n "$DD_API_KEY" ] && [ -n "$DD_APPLICATION_KEY" ]; then
      info "Using API key authentication for Datadog MCP server..."
      if claude mcp add -s user --transport http datadog-mcp https://mcp.datadoghq.com/api/unstable/mcp-server/mcp \
        -H "DD_API_KEY: $DD_API_KEY" -H "DD_APPLICATION_KEY: $DD_APPLICATION_KEY" 2>/dev/null; then
        info "Added Datadog MCP server with API key authentication"
      else
        warn "Failed to add Datadog MCP server with API keys"
      fi
    else
      # Use OAuth 2.0 authentication (default)
      if claude mcp add -s user --transport http datadog-mcp https://mcp.datadoghq.com/api/unstable/mcp-server/mcp 2>/dev/null; then
        info "Added Datadog MCP server (OAuth 2.0 authentication)"
        info "You'll be prompted to authenticate via browser on first use"
      else
        warn "Failed to add Datadog MCP server"
      fi
    fi
  else
    info "Datadog MCP server already exists, skipping"
  fi
}

