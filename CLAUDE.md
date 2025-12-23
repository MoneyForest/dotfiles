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

## GitHub Actions CD 3-Layer Architecture

When designing CD workflows for GitHub Actions, use a 3-layer architecture for maintainability:

### Layer Structure

| Layer | File Pattern | Role |
|-------|-------------|------|
| Layer 1 | `_cd.yml` | Reusable workflow (`workflow_call`) - shared logic |
| Layer 2 | `cd-{env}.yml` | Caller workflows - environment-specific parameters |
| Layer 3 | `composites/` or `.github/actions/` | Composite actions - individual steps |

### Layer 1: Reusable Workflow (`_cd.yml`)

```yaml
name: CD

on:
  workflow_call:
    inputs:
      env:
        required: true
        type: string
      project_id:
        required: true
        type: string
      # ... other environment-specific inputs
    secrets:
      DEPLOY_TOKEN:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/workflows/composites/setup
      - uses: ./.github/workflows/composites/build-and-push
        with:
          project_id: ${{ inputs.project_id }}
          # ...

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/workflows/composites/deploy
        with:
          env: ${{ inputs.env }}
          # ...
```

### Layer 2: Caller Workflows (`cd-{env}.yml`)

```yaml
name: CD Dev

on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write

concurrency:
  group: cd-dev
  cancel-in-progress: false

jobs:
  cd:
    uses: ./.github/workflows/_cd.yml
    with:
      env: dev
      project_id: my-project-dev
      # environment-specific values only
    secrets:
      DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

### Layer 3: Composite Actions (`composites/` or `.github/actions/`)

```yaml
# .github/workflows/composites/build-and-push/action.yml
name: Build and Push
inputs:
  project_id:
    required: true
runs:
  using: composite
  steps:
    - name: Build
      shell: bash
      run: docker build -t ${{ inputs.project_id }} .
    - name: Push
      shell: bash
      run: docker push ${{ inputs.project_id }}
```

### Benefits

- **DRY**: Common logic in Layer 1, environment values in Layer 2
- **Maintainability**: Changes to deploy process only need Layer 1 updates
- **Visibility**: Each environment has its own workflow file with clear triggers
- **Concurrency**: Each caller can define its own concurrency group

### Naming Conventions

- Reusable workflows: Prefix with `_` (e.g., `_cd.yml`, `_terraform-plan-apply.yml`)
- Caller workflows: Include environment (e.g., `cd-dev.yml`, `cd-prd.yml`)
- Composite actions: Place in `composites/` or `.github/actions/` directory