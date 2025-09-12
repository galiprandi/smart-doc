# Smart Doc — Usage and Recipes

This guide complements the README with alternative setups, advanced options, and troubleshooting.

## Requirements recap
- Secret: `SMART_DOC_API_TOKEN` (exported as `OPENAI_API_KEY`).
- Job permissions (for `gh` PR ops):
  - `permissions.contents: write`
  - `permissions.pull-requests: write`
- Optional: `GH_TOKEN` (PAT with `repo`) if your org restricts `GITHUB_TOKEN`.

## Minimal workflow (from README)
```yaml
ame: Smart Doc
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
          smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}
          branch: main
          docs_folder: docs
          generate_history: 'true'
```

## Alternative triggers

### GitFlow, release branches, PR-only
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

### PR-only previews (no pushes)
```yaml
on:
  pull_request:
    branches: [ main, develop ]
```

### Monorepo selective (paths filters)
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

## Authentication options for `gh`
- Default: `GITHUB_TOKEN` with job permissions `contents: write` and `pull-requests: write`.
- PAT (optional): store as `GH_PAT` and expose it as `GH_TOKEN` if needed:
```yaml
env:
  GH_TOKEN: ${{ secrets.GH_PAT }}
```

## Merge orchestration (resilient)
Inputs exposed by the Action for robust merges:
- `merge_mode`: `auto` | `immediate` | `off` (default `auto`).
- `merge_wait_seconds`: poll interval to wait for mergeability (default `10`).
- `merge_max_attempts`: max polling attempts (default `30`).
- `ready_pr_if_draft`: convert draft PRs to ready (default `true`).

Examples:

Queue auto-merge (default):
```yaml
with:
  smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}
  merge_mode: auto
```

Merge immediately when mergeable (waits for checks):
```yaml
with:
  smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}
  merge_mode: immediate
  merge_wait_seconds: '10'
  merge_max_attempts: '30'
  ready_pr_if_draft: 'true'
```

Leave PR open (no merge action):
```yaml
with:
  smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}
  merge_mode: off
```

## Anti-loop and concurrency
- Use `paths-ignore` for `docs/**` and `SMART_TIMELINE.md` on push.
- Keep a job-level `concurrency` with `cancel-in-progress: true`.
- Optional job `if:` guard to skip pushes from Smart Doc branches and the Actions bot.

## Troubleshooting
- PR not created
  - Ensure job permissions (contents + PRs) and a token available to `gh` (`GITHUB_TOKEN` or `GH_TOKEN`).
  - Check `gh auth status` output in logs.
- Auto-merge not enqueued/failed
  - Repo: enable “Allow auto-merge”.
  - PR is not draft; approvals and status checks satisfied.
  - Merge method allowed (squash).
  - Use `merge_mode: immediate` to squash-merge as soon as mergeable.
- Push rejected (non-fast-forward)
  - The Action uses a resilient strategy (fetch + `--force-with-lease`) on the branch `smart-doc/docs-update-<sha>`.

## Notes
- Smart Doc writes only under `docs/` (English) and optionally appends `SMART_TIMELINE.md`.
- It never pushes directly to protected branches; it opens a PR instead.
