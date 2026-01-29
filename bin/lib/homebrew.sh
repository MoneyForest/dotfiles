#!/bin/zsh

install_homebrew() {
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
}

install_brewfile() {
  local current_dir="$1"

  if [ -f "$current_dir/brew/Brewfile" ]; then
    info "Installing Homebrew packages from Brewfile..."
    brew bundle --file="$current_dir/brew/Brewfile"
  else
    warn "Brewfile not found at $current_dir/brew/Brewfile"
  fi
}
