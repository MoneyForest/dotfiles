#!/bin/zsh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
  echo "${GREEN}[INFO]${NC} $1"
}

warn() {
  echo "${YELLOW}[WARN]${NC} $1"
}

error() {
  echo "${RED}[ERROR]${NC} $1"
}

# Set directory
current_dir=$(pwd)

# Install Homebrew if not installed
if ! type brew &>/dev/null; then
  warn "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ $(uname -m) == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if type brew &>/dev/null; then
    info "Homebrew installed successfully"
  else
    error "Failed to install Homebrew. Please install manually."
    exit 1
  fi
else
  info "Homebrew is already installed"
fi

# Set dotfiles with their corresponding directories
typeset -A dotfiles
dotfiles=(
    gitconfig git
    gitignore_global git
    vimrc vim
    zpreztorc zsh
    zshrc zsh
)

# Link common dotfiles
info "Linking dotfiles..."
for dotfile key in ${(kv)dotfiles}; do
  dir=$dotfiles[$dotfile]
  if [ -f "$current_dir/$dir/$dotfile" ]; then
    ln -sf "$current_dir/$dir/$dotfile" ~/.$dotfile
  else
    warn "$dotfile does not exist in directory $dir and was not linked"
  fi
done

# Initialize and update git submodules (for Prezto)
info "Initializing git submodules..."
git submodule update --init --recursive

# Link prezto directory to ~/.zprezto
if [ -d "$current_dir/prezto" ]; then
  if [ -e ~/.zprezto ] && [ ! -L ~/.zprezto ]; then
    warn "~/.zprezto already exists and is not a symlink. Skipping link creation"
  else
    ln -sf "$current_dir/prezto" ~/.zprezto
    info "Prezto directory was linked to ~/.zprezto"
  fi
else
  warn "prezto directory does not exist. Make sure submodule is initialized"
fi

# Remove any recursive symlinks that may have been created
rm -f "$current_dir/prezto/prezto"

# Link Prezto configuration files
prezto_files=("zlogin" "zlogout" "zpreztorc" "zprofile" "zshenv" "zshrc")

for file in "${prezto_files[@]}"; do
  if [ -f "$current_dir/zsh/$file" ]; then
    ln -sf "$current_dir/zsh/$file" ~/.$file
  else
    warn "$file does not exist in the zsh directory and was not linked"
  fi
done

# Link VSCode/Cursor settings
settings_src="$current_dir/vscode/settings.json"
code_settings_dest="$HOME/Library/Application Support/Code/User/settings.json"
cursor_settings_dest="$HOME/Library/Application Support/Cursor/User/settings.json"

if [ -f "$settings_src" ]; then
  # Create directories if they don't exist
  mkdir -p "$(dirname "$code_settings_dest")"
  mkdir -p "$(dirname "$cursor_settings_dest")"

  ln -sf "$settings_src" "$code_settings_dest" 2>/dev/null && info "VSCode settings.json was linked" || warn "VSCode not installed, skipping settings link"
  ln -sf "$settings_src" "$cursor_settings_dest" 2>/dev/null && info "Cursor settings.json was linked" || warn "Cursor not installed, skipping settings link"
else
  warn "settings.json does not exist and was not linked"
fi

# Link Claude Code settings
claude_dir="$HOME/.claude"
mkdir -p "$claude_dir"

claude_settings_src="$current_dir/claude/settings.json"
claude_settings_dest="$claude_dir/settings.json"

if [ -f "$claude_settings_src" ]; then
  ln -sf "$claude_settings_src" "$claude_settings_dest" && info "Claude Code settings.json was linked" || warn "Failed to link Claude Code settings"
else
  warn "Claude Code settings.json does not exist and was not linked"
fi

# Install Homebrew packages
if [ -f "$current_dir/brew/Brewfile" ]; then
  info "Installing Homebrew packages from Brewfile..."
  brew bundle --file="$current_dir/brew/Brewfile"
else
  warn "Brewfile not found at $current_dir/brew/Brewfile"
fi

# Initialize anyenv if needed
if command -v anyenv &>/dev/null; then
  info "Initializing anyenv..."
  eval "$(anyenv init -)"

  # Install anyenv-update plugin if not exists
  if [ ! -d "$(anyenv root)/plugins/anyenv-update" ]; then
    mkdir -p "$(anyenv root)/plugins"
    git clone https://github.com/znz/anyenv-update.git "$(anyenv root)/plugins/anyenv-update"
  fi
else
  warn "anyenv not found. Skipping anyenv initialization"
fi

# Install nodenv via anyenv for MCP servers
if command -v anyenv &>/dev/null; then
  info "Setting up nodenv via anyenv..."

  # Install nodenv if not already installed
  if ! anyenv versions 2>/dev/null | grep -q nodenv; then
    info "Installing nodenv..."
    anyenv install nodenv
    eval "$(anyenv init -)"
  else
    info "nodenv is already installed"
  fi

  # Install Node.js LTS version
  if command -v nodenv &>/dev/null; then
    NODE_VERSION="24.11.1"  # Latest LTS version

    if ! nodenv versions | grep -q "$NODE_VERSION"; then
      info "Installing Node.js $NODE_VERSION..."
      nodenv install "$NODE_VERSION"
      nodenv global "$NODE_VERSION"
      info "Node.js $NODE_VERSION installed and set as global"
    else
      info "Node.js $NODE_VERSION is already installed"
    fi
  fi
else
  warn "anyenv not found. Node.js will not be installed"
fi

# Check Node.js for MCP servers
if ! command -v node &>/dev/null; then
  warn "Node.js not found. MCP servers require Node.js to run."
  warn "Please restart your terminal and run this script again after anyenv initialization."
else
  info "Node.js is installed: $(node --version)"
fi

# Install Claude Code MCP servers
if command -v claude &>/dev/null; then
  info "Installing Claude Code MCP servers..."

  # Define MCP servers to install (all use npx, all are authentication-free)
  # Note: WebFetch functionality is already built into Claude Code, so no separate fetch server needed
  # Note: aws-knowledge-mcp-server replaces aws-documentation-mcp-server with additional regional features
  mcp_servers=(
    "terraform-mcp-server|stdio|npx|-y terraform-mcp-server"
    "aws-knowledge-mcp-server|stdio|npx|mcp-remote https://knowledge-mcp.global.api.aws"
    "memory|stdio|npx|-y @modelcontextprotocol/server-memory"
    "sequential-thinking|stdio|npx|-y @modelcontextprotocol/server-sequential-thinking"
    "playwright|stdio|npx|-y @playwright/mcp"
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
  # Note: GitHub MCP server requires a Personal Access Token (PAT)
  # Set GITHUB_PAT environment variable before running this script, or configure manually after installation
  if ! claude mcp list 2>/dev/null | grep -q "^github"; then
    if [ -n "$GITHUB_PAT" ]; then
      info "Installing GitHub MCP server with authentication..."
      if claude mcp add --transport http github https://api.githubcopilot.com/mcp -H "Authorization: Bearer $GITHUB_PAT" 2>/dev/null; then
        info "Added GitHub MCP server"
      else
        warn "Failed to add GitHub MCP server. You may need to configure it manually."
      fi
    else
      warn "GITHUB_PAT environment variable not set. Skipping GitHub MCP server installation."
      warn "To install manually, run: claude mcp add --transport http github https://api.githubcopilot.com/mcp -H \"Authorization: Bearer YOUR_GITHUB_PAT\""
    fi
  else
    info "GitHub MCP server already exists, skipping"
  fi
else
  warn "Claude Code CLI not found. Install Claude Code to enable MCP server setup."
fi

# Install ASDF tools
if [ -f "$current_dir/asdf/.tool-versions" ]; then
  info "Installing ASDF tools from .tool-versions..."
  while IFS=' ' read -r tool version || [ -n "$tool" ]; do
    # Skip empty lines
    [[ -z "$tool" ]] && continue

    info "Setting up $tool $version..."
    asdf plugin add "$tool" 2>/dev/null || true
    asdf install "$tool" "$version"
    asdf set -u "$tool" "$version"
  done < "$current_dir/asdf/.tool-versions"
else
  warn ".tool-versions file not found in $current_dir/asdf/"
fi

info "Installation complete!"
info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
