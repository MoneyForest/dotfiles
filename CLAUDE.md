# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository that manages development environment configurations for macOS. It uses a symlink-based approach to centralize configuration files for various development tools.

## Key Commands

### Initial Setup
```bash
./bin/install.sh
```
This script performs the complete environment setup:
- Creates symlinks for all configuration files to their appropriate locations
- Installs Homebrew packages from `brew/Brewfile`
- Installs ASDF tools from `asdf/.tool-versions`
- Initializes git submodules (Prezto)
- Links VSCode/Cursor settings

### Package Management
```bash
# Install/update Homebrew packages
brew bundle --file=brew/Brewfile

# Install ASDF tools and versions
asdf install
```

### Configuration Updates
After modifying any configuration files, they take effect immediately via symlinks. For shell configurations:
```bash
source ~/.zshrc
```

## Architecture

### Configuration Structure
- **Symlink Strategy**: All dotfiles are symlinked from this repo to their expected system locations
- **Modular Organization**: Configurations grouped by tool (git/, vim/, zsh/, etc.)
- **Environment Management**: Uses both ASDF and Anyenv for version management

### Key Configuration Files
- `bin/install.sh`: Master installation script with symlink mappings
- `brew/Brewfile`: Homebrew package definitions
- `asdf/.tool-versions`: Tool versions for Kubernetes, MySQL, etc.
- `zsh/zshrc`: Shell configuration with Prezto integration

### Tool Integration
- **Shell**: Zsh with Prezto framework, includes Peco for fuzzy search
- **Version Managers**: ASDF for tools, Anyenv for language runtimes
- **Development**: Go workspace setup, Kubernetes aliases, Docker integration
- **Editors**: Vim configuration, VSCode/Cursor settings shared

### Environment Variables & Paths
The shell configuration manages multiple tool paths:
- Homebrew (`/opt/homebrew/bin`)
- Go workspace (`$GOPATH/bin`)
- Language version managers (Pyenv, Rbenv, Tfenv)
- ASDF tool installations

### Private Configuration
Supports private settings via `~/.zsh_private` for sensitive or machine-specific configurations.