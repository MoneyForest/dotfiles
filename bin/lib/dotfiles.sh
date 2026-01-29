#!/bin/zsh

link_dotfiles() {
  local current_dir="$1"

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
}

setup_prezto() {
  local current_dir="$1"

  # Initialize and update git submodules (for Prezto)
  info "Initializing git submodules..."
  git submodule update --init --recursive

  # Link prezto directory to ~/.zprezto
  if [ -d "$current_dir/prezto" ]; then
    if [ -e ~/.zprezto ] && [ ! -L ~/.zprezto ]; then
      warn "~/.zprezto already exists and is not a symlink. Skipping link creation"
    else
      ln -sfn "$current_dir/prezto" ~/.zprezto
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
}

link_editor_settings() {
  local current_dir="$1"

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
}
