---
paths: .github/workflows/**/*.yml
---

# GitHub Actions CD 3-Layer Architecture

When designing CD workflows for GitHub Actions, use a 3-layer architecture for maintainability:

## Layer Structure

| Layer | File Pattern | Role |
|-------|-------------|------|
| Layer 1 | `_cd.yml` | Reusable workflow (`workflow_call`) - shared logic |
| Layer 2 | `cd-{env}.yml` | Caller workflows - environment-specific parameters |
| Layer 3 | `composites/` or `.github/actions/` | Composite actions - individual steps |

## Layer 1: Reusable Workflow (`_cd.yml`)

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

## Layer 2: Caller Workflows (`cd-{env}.yml`)

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

## Layer 3: Composite Actions (`composites/` or `.github/actions/`)

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

## Benefits

- **DRY**: Common logic in Layer 1, environment values in Layer 2
- **Maintainability**: Changes to deploy process only need Layer 1 updates
- **Visibility**: Each environment has its own workflow file with clear triggers
- **Concurrency**: Each caller can define its own concurrency group

## Naming Conventions

- Reusable workflows: Prefix with `_` (e.g., `_cd.yml`, `_terraform-plan-apply.yml`)
- Caller workflows: Include environment (e.g., `cd-dev.yml`, `cd-prd.yml`)
- Composite actions: Place in `composites/` or `.github/actions/` directory
