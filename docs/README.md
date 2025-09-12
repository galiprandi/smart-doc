Smart Doc Documentation

Purpose
- Keep repository documentation living and change‑driven by analyzing diffs and writing updates under `docs/` (and optionally `HISTORY.md`).

This Commit
- CI workflow renamed job to `smart-doc` and added a self‑commit guard to avoid generation loops on pushes.
- Added PR‑only docs preview via `actions/upload-artifact` (uploads `docs/**` and `HISTORY.md`).
- Workflow example in README keeps `galiprandi/smart-doc@v1`; internal CI uses local action `./` and supports optional `prompt_template`.

Quickstart
- Trigger: Runs on push/PR via GitHub Actions.
- Auth: Set `SMART_DOC_API_TOKEN` (exported as `OPENAI_API_KEY`).
- Output: Writes docs in `docs/`. Pushes commits on `main`; PRs do not push.

Minimal workflow
```yaml
name: Smart Doc
on:
  push:
    branches: [main]

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

Common Commands
- The action invokes Codex CLI in this order:
  - `code exec --sandbox workspace-write "<prompt>"`
  - `codex exec --sandbox workspace-write "<prompt>"`
  - `npx -y @openai/codex exec --sandbox workspace-write "<prompt>"`

Folder Structure
- `docs/` — Generated and maintained documentation (this folder).
- `entrypoint.sh` — Orchestrates prompts, diffs, and CLI execution.

Notes
- Provider compatibility: OpenAI (Codex/GPT‑5) is primary; Qwen/Qwen‑Code is adaptable. TODO: Document Qwen setup if adopted.
- PRs in this repo upload a preview artifact; pushes to `main` commit docs directly.

Change Log Format (HISTORY.md)
- Append‑only; never rewrite or reorder prior entries.
- English only.
- Exact entry format:
  ## <Concise title>
  - Date: YYYY-MM-DD
  - Scope: <areas/modules>
  - TL;DR: <one-sentence summary>
- Spacing rules:
  - Ensure a blank line before each new entry (add one first if file ends without newline).
  - Leave a single blank line after each entry; separate entries with exactly one blank line.
  - Do not add horizontal rules or extra headings. End the file with a single trailing newline.
