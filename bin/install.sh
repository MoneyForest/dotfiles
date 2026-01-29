#!/bin/zsh

# Get the directory where this script is located
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="${SCRIPT_DIR:h}"

# Source library files
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/homebrew.sh"
source "$SCRIPT_DIR/lib/dotfiles.sh"
source "$SCRIPT_DIR/lib/claude.sh"
source "$SCRIPT_DIR/lib/devtools.sh"

main() {
  info "Starting dotfiles installation..."

  # Homebrew
  install_homebrew
  install_brewfile "$DOTFILES_DIR"

  # Dotfiles & Shell
  link_dotfiles "$DOTFILES_DIR"
  setup_prezto "$DOTFILES_DIR"
  link_editor_settings "$DOTFILES_DIR"

  # Claude Code
  link_claude_settings "$DOTFILES_DIR"

  # Development tools
  setup_anyenv
  setup_nodenv
  check_nodejs
  install_precommit
  install_asdf_tools "$DOTFILES_DIR"

  # MCP servers (requires Node.js)
  install_mcp_servers

  info "Installation complete!"
  info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
}

main "$@"
