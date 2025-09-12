[![Smart Doc](https://github.com/galiprandi/smart-doc/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/galiprandi/smart-doc/actions/workflows/test.yml)

# Smart Doc — Living documentation for your repository

Smart Doc keeps your documentation fresh automatically on every integration to `main`.

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
- On merges to `main`, Smart Doc:
  - Detects changed files and unified diffs.
  - Updates or creates pages in `docs/` with explanations and diagrams.
  - Commits the resulting documentation automatically.
- On pull requests, you get a safe preview without pushing commits.

Minimal setup
- One secret: `SMART_DOC_API_TOKEN` (your API key; exported as `OPENAI_API_KEY`).
- A simple workflow pointing to this Action.

Minimal workflow example
```yaml
name: Smart Doc
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

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

Model compatibility
- OpenAI (Codex/GPT‑5): first‑class support.
- Qwen / Qwen‑Code: easily adaptable by configuring your model provider.

FAQ
- Does it overwrite everything? No. It only updates documentation tied to the current commit’s diff.
- Does it generate diagrams? Yes, Mermaid diagrams that stay consistent with the changes.
- Does it run on PRs? Yes, without pushing commits; on `main` it commits changes automatically.

License
MIT
