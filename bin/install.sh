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
prezto_files=("zlogin" "zlogout" "zpreztorc" "zprofile", "zshenv", "zshrc")

for file in "${prezto_files[@]}"; do
  if [ -f "$current_dir/zsh/$file" ]; then
    ln -sf "$current_dir/zsh/$file" ~/.$file
  else
    echo "Warning: $file does not exist in the zsh directory and was not linked."
  fi
done

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
