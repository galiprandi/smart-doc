[![Smart Doc](https://github.com/galiprandi/smart-doc/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/galiprandi/smart-doc/actions/workflows/test.yml)

# Smart Doc — Living documentation for your repository

Smart Doc keeps your documentation fresh automatically on every integration (main, develop, release, or PRs) — you choose the trigger.

Benefits
- Change‑driven updates: turns each commit diff into clear, useful docs under `docs/` (and optionally `HISTORY.md`).
- Architecture and modules, minus the friction: generates concise summaries, Mermaid diagrams, and per‑module pages when relevant.
- Zero manual effort: runs as a GitHub Action on every push or PR; pushes commits on `main`, never on PRs.
- Flexible by design: works with any stack. Built for OpenAI (Codex/GPT‑5) and easy to adapt for Qwen/Qwen‑Code.

Why Smart Doc
- Reduce documentation debt: stop chasing stale READMEs and diagrams.
- Faster onboarding: newcomers grasp “what changed” in minutes.
- Stay focused: only touches docs related to the change, not the whole site.
- Scales with you: from single repos to large monorepos.

How it works (at a glance)
- On your chosen trigger (e.g., merges to `main` or `develop`, or PRs), Smart Doc:
  - Detects changed files and unified diffs.
  - Updates or creates pages in `docs/` with explanations and diagrams (English, change‑only).
  - Opens an auto‑merge Pull Request to `main` with the generated docs — perfect for protected branches.
- On pull requests, you get a safe preview without pushing commits.

Minimal setup
- One secret: `SMART_DOC_API_TOKEN` (your API key; exported as `OPENAI_API_KEY`).
- A simple workflow pointing to this Action.

Minimal workflow example (main and PRs)
```yaml
name: Smart Doc
on:
  push:
    branches: [ main ]
    paths-ignore:
      - 'docs/**'
      - 'HISTORY.md'
  pull_request:
    branches: [ main ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  update-docs:
    if: >
      ${{ github.event_name != 'push' || (
            !startsWith(github.ref_name, 'smart-doc/docs-update-') &&
            github.actor != 'github-actions[bot]'
          ) }}
    runs-on: ubuntu-latest
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
          # Optional: custom prompt
          # prompt_template: prompts/default.md
```

Model compatibility
- OpenAI (Codex/GPT‑5): first‑class support.
- Qwen / Qwen‑Code: easily adaptable by configuring your model provider.

FAQ
- Does it overwrite everything? No. It only updates documentation tied to the current commit’s diff.
- Does it generate diagrams? Yes, Mermaid diagrams that stay consistent with the changes.
- Does it run on PRs? Yes, without pushing commits; on `main` it commits changes automatically.

License
MIT

<!-- chore: trigger Smart Doc PR flow test -->

Customize triggers (GitFlow, release branches, PR-only)
```yaml
on:
  push:
    branches:
      - develop         # GitFlow
      - release/*       # release branches
      - main            # trunk/main
    paths-ignore:
      - 'docs/**'
      - 'HISTORY.md'
  pull_request:
    branches: [ main, develop ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

PR-only workflow example (no pushes, safe previews)
```yaml
name: Smart Doc (PR only)
on:
  pull_request:
    branches: [ main, develop ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  update-docs:
    runs-on: ubuntu-latest
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
          # Optional: custom prompt
          # prompt_template: prompts/default.md
```

Quick recipes

| Scenario | on.push | on.pull_request | Notes |
| --- | --- | --- | --- |
| Trunk-based (main only) | `branches: [ main ]` + `paths-ignore` for docs | `branches: [ main ]` | Most common. Auto‑merge PR targets `main`. |
| GitFlow (develop + main) | `branches: [ develop, main ]` + `paths-ignore` | `branches: [ develop, main ]` | Document on both develop and main. |
| Release branches | `branches: [ release/*, main ]` + `paths-ignore` | `branches: [ main ]` | Keep release docs in sync pre‑merge. |
| PR‑only previews | – | `branches: [ main, develop ]` | Never pushes. Safe previews in PRs. |
| Monorepo selective | Use `paths:` filters per app/package | Same | Run only when certain folders change. |

Tip: keep `concurrency.cancel-in-progress: true` and the anti‑loop job condition to avoid cycles when Smart Doc opens a docs PR.
