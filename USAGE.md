# 📘 Smart Doc — Usage and Recipes

This guide complements the README with alternative setups, advanced options, and troubleshooting.

## 🧰 Requirements recap
- Secret: `OPENAI_API_KEY` (your OpenAI API key).
- Job permissions:
  - `permissions.contents: write`
  - `permissions.pull-requests: write`
  - The default `GITHUB_TOKEN` is sufficient.

## ⚡️ Minimal workflow (from README)
```yaml
name: Smart Doc
on:
  push:
    branches: [ main ]
    paths-ignore:
      - 'docs/**'
      - 'SMART_TIMELINE.md'
  pull_request:
    branches: [ main ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  update-docs:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Smart Doc
        uses: galiprandi/smart-doc@v1
        with:
          openai_api_key: ${{ secrets.OPENAI_API_KEY }}
          model: gpt-5-mini
```

## 🔔 Alternative triggers

### 🔀 GitFlow, release branches, PR-only
```yaml
on:
  push:
    branches:
      - develop
      - release/*
      - main
    paths-ignore:
      - 'docs/**'
      - 'SMART_TIMELINE.md'
  pull_request:
    branches: [ main, develop ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 👀 PR-only previews (no pushes)
```yaml
on:
  pull_request:
    branches: [ main, develop ]
```

### 🧩 Monorepo selective (paths filters)
```yaml
on:
  push:
    branches: [ main ]
    paths:
      - apps/frontend/**
      - packages/ui/**
    paths-ignore:
      - 'docs/**'
      - 'SMART_TIMELINE.md'
  pull_request:
    branches: [ main ]
    paths:
      - apps/frontend/**
      - packages/ui/**
```

### 🧩 Monorepo — per-package jobs (matrix)
Run Smart Doc separately for multiple packages/workspaces. Each job scopes `paths` and can write docs into a package‑specific folder (optional) or a shared `docs/` with module pages.

```yaml
on:
  push:
    branches: [ main ]
    paths-ignore:
      - 'docs/**'
      - 'SMART_TIMELINE.md'
  pull_request:
    branches: [ main ]

jobs:
  update-docs:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        scope:
          - name: frontend
            paths: 'apps/frontend/**'
          - name: api
            paths: 'apps/api/**'
          - name: ui
            paths: 'packages/ui/**'
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Skip if matrix scope not touched
        id: changed
        run: |
          set -euo pipefail
          BASE="${{ github.event_name == 'pull_request' && github.base_ref || 'origin/main' }}"
          git fetch origin "$BASE" --depth=1 || true
          CHANGED=$(git diff --name-only ${BASE:+"$BASE"}..."${{ github.sha }}" || true)
          if echo "$CHANGED" | grep -E '^${{ matrix.scope.paths }}'; then
            echo "run=true" >> "$GITHUB_OUTPUT"
          else
            echo "run=false" >> "$GITHUB_OUTPUT"
          fi

      - name: Smart Doc (${{ matrix.scope.name }})
        if: steps.changed.outputs.run == 'true'
        uses: galiprandi/smart-doc@v1
        with:
          openai_api_key: ${{ secrets.OPENAI_API_KEY }}
          model: gpt-5-mini
```

### 🌿 Multi-branch strategy (develop + main)
Use previews on PRs (develop, main) and publish only on main.

```yaml
on:
  push:
    branches: [ main ]
    paths-ignore:
      - 'docs/**'
      - 'SMART_TIMELINE.md'
  pull_request:
    branches: [ main, develop ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 📦 PR preview artifact (optional)
Download generated docs from PR runs without publishing:

```yaml
- name: Upload docs preview
  if: ${{ github.event_name == 'pull_request' }}
  uses: actions/upload-artifact@v4
  with:
    name: smart-doc-preview
    path: |
      docs/**
      SMART_TIMELINE.md
    if-no-files-found: warn
```

## 🔁 Anti-loop and concurrency
- Use `paths-ignore` for `docs/**` and `SMART_TIMELINE.md` on push.
- Keep a job-level `concurrency` with `cancel-in-progress: true`.
- Optional job `if:` guard to skip pushes from Smart Doc branches and the Actions bot.

## 🛠️ Troubleshooting
- PR not created
  - Ensure job permissions (contents + PRs) and a token available to `gh` (`GITHUB_TOKEN` or `GH_TOKEN`).
  - Check `gh auth status` output in logs.
- Push rejected (non-fast-forward)
  - The Action uses a resilient strategy (fetch + `--force-with-lease`) on the branch `smart-doc/docs-update-<sha>`.

## 📝 Notes
- Smart Doc writes only under `docs/` (English) and optionally appends `SMART_TIMELINE.md`.
- It never pushes directly to protected branches; it opens a PR instead.

## 🧠 Choosing a model
- Recommended: `gpt-5-mini`.
- Override with the `model` input when needed.
- The Action passes `--model` to the CLI when supported and exports `OPENAI_MODEL` and `CODEX_MODEL`.
- If you see `401 Unauthorized`, verify `OPENAI_API_KEY` and model access.

## ⚓️ Use as hook / remote bootstrap
Run Smart Doc without installing the Action by calling the remote bootstrap. It soft‑fails on missing secrets and won’t break your pipeline.

- Local/CI one‑liner (after exporting `OPENAI_API_KEY`):
  - `curl -fsSL https://raw.githubusercontent.com/galiprandi/smart-doc/v1/bootstrap.sh | bash`

Git pre‑push (remote, recommended)
Create `.git/hooks/pre-push` and make it executable `chmod +x .git/hooks/pre-push`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Optional: load .env (provides OPENAI_API_KEY)
if [ -f .env ]; then
  set -o allexport; source .env; set +o allexport
fi

# Run Smart Doc via remote bootstrap (soft‑fail; never blocks push)
curl -fsSL https://raw.githubusercontent.com/galiprandi/smart-doc/v1/bootstrap.sh | bash || true

# Optionally include generated docs in this push
if ! git diff --quiet -- docs SMART_TIMELINE.md; then
  git add docs SMART_TIMELINE.md || true
  if ! git diff --cached --quiet; then
    git commit -m "docs: update generated docs (pre-push)"
  fi
fi

exit 0
```

Example override:
```yaml
with:
  openai_api_key: ${{ secrets.OPENAI_API_KEY }}
  model: gpt-4o-mini
```
