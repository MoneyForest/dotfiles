#!/bin/zsh

# set directory
current_dir=$(pwd)

# set dotfiles with their corresponding directories
typeset -A dotfiles
dotfiles=(
    gitconfig git
    gitignore_global git
    vimrc vim
    zpreztorc zsh
    zshrc zsh
)

# Link common dotfiles
for dotfile key in ${(kv)dotfiles}; do
  dir=$dotfiles[$dotfile]
  if [ -f "$current_dir/$dir/$dotfile" ]; then
    ln -sf "$current_dir/$dir/$dotfile" ~/.$dotfile
  else
    echo "Warning: $dotfile does not exist in directory $dir and was not linked."
  fi
done

# Link Prezto configurations
prezto_files=("zlogin" "zlogout" "zpreztorc" "zprofile" "zshenv" "zshrc")

for file in "${prezto_files[@]}"; do
  if [ -f "$current_dir/zsh/$file" ]; then
    ln -sf "$current_dir/zsh/$file" ~/.$file
    echo "Info: $file exists in the zsh directory and was linked."
  else
    echo "Warning: $file does not exist in the zsh directory and was not linked."
  fi
done

# Link VSCode settings
settings_src="$current_dir/vscode/settings.json"
code_settings_dest="$HOME/Library/Application Support/Code/User/settings.json"
cursor_settings_dest="$HOME/Library/Application Support/Cursor/User/settings.json"

if [ -f "$settings_src" ]; then
  ln -sf "$settings_src" "$code_settings_dest"
  ln -sf "$settings_src" "$cursor_settings_dest"
  echo "Info: settings.json was linked."
else
  echo "Warning: settings.json does not exist and was not linked."
fi

# Initialize and update the submodule (for Prezto)
git submodule update --init --recursive

# Check for Homebrew and run brew bundle if Brewfile exists
if type brew &>/dev/null; then
  if [ -f "$current_dir/Brew/Brewfile" ]; then
    echo "Found Brewfile. Installing brew packages..."
    brew bundle --file="$current_dir/Brew/Brewfile"
  fi
else
  echo "Homebrew not found. Please install Homebrew first."
fi

# .tool-versionsファイルに記載されているツールをインストール
if [ -f "$current_dir/asdf/.tool-versions" ]; then
  while IFS=' ' read -r tool version || [ -n "$tool" ]; do
    asdf plugin add "$tool" 2>/dev/null || true
    asdf install "$tool" "$version"
    asdf global "$tool" "$version"
  done < "$current_dir/asdf/.tool-versions"
else
  echo "Warning: .tool-versions file not found in $current_dir/asdf/"
fi
