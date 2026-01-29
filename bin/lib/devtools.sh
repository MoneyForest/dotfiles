#!/bin/zsh

setup_anyenv() {
  if ! command -v anyenv &>/dev/null; then
    warn "anyenv not found. Skipping anyenv initialization"
    return
  fi

  info "Initializing anyenv..."
  eval "$(anyenv init -)"

  # Install anyenv-update plugin if not exists
  if [ ! -d "$(anyenv root)/plugins/anyenv-update" ]; then
    mkdir -p "$(anyenv root)/plugins"
    git clone https://github.com/znz/anyenv-update.git "$(anyenv root)/plugins/anyenv-update"
  fi
}

setup_nodenv() {
  if ! command -v anyenv &>/dev/null; then
    warn "anyenv not found. Node.js will not be installed"
    return
  fi

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
    local NODE_VERSION="24.11.1"  # Latest LTS version

    if ! nodenv versions | grep -q "$NODE_VERSION"; then
      info "Installing Node.js $NODE_VERSION..."
      nodenv install "$NODE_VERSION"
      nodenv global "$NODE_VERSION"
      info "Node.js $NODE_VERSION installed and set as global"
    else
      info "Node.js $NODE_VERSION is already installed"
    fi
  fi
}

check_nodejs() {
  if ! command -v node &>/dev/null; then
    warn "Node.js not found. MCP servers require Node.js to run."
    warn "Please restart your terminal and run this script again after anyenv initialization."
  else
    info "Node.js is installed: $(node --version)"
  fi
}

install_precommit() {
  if ! command -v pip3 &>/dev/null; then
    warn "pip3 not found. Skipping pre-commit installation"
    return
  fi

  if ! command -v pre-commit &>/dev/null; then
    info "Installing pre-commit..."
    pip3 install pre-commit
    info "pre-commit installed successfully"
  else
    info "pre-commit is already installed"
  fi
}

install_asdf_tools() {
  local current_dir="$1"

  if [ ! -f "$current_dir/asdf/.tool-versions" ]; then
    warn ".tool-versions file not found in $current_dir/asdf/"
    return
  fi

  info "Installing ASDF tools from .tool-versions..."
  while IFS=' ' read -r tool version || [ -n "$tool" ]; do
    # Skip empty lines
    [[ -z "$tool" ]] && continue

    info "Setting up $tool $version..."
    asdf plugin add "$tool" 2>/dev/null || true
    asdf install "$tool" "$version"
    asdf set -u "$tool" "$version"
  done < "$current_dir/asdf/.tool-versions"
}
