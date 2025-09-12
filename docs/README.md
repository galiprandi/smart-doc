Smart Doc Documentation

Purpose
- Automates change-focused documentation updates for this repository by analyzing Git diffs and generating content under `docs/`.

What Changed in This Revision
- Codex CLI is now invoked without an explicit approval flag. The environment variable `CODEX_APPROVAL` and the `--approval` CLI option were removed from `entrypoint.sh`.
- The Codex sandbox remains `workspace-write`, and `CODEX_REASONING_EFFORT` is set to `medium`.

Quickstart
- Trigger: Run via the GitHub Action workflow on push/PR.
- Auth: Set `SMART_DOC_API_TOKEN` (mapped to `OPENAI_API_KEY`).
- Output: Generated docs are written under `docs/` and committed on push events when changes are detected.

Common Commands
- The action attempts to invoke Codex CLI in this order:
  - `code exec --sandbox workspace-write "<prompt>"`
  - `codex exec --sandbox workspace-write "<prompt>"`
  - `npx -y @openai/codex exec --sandbox workspace-write "<prompt>"`

Folder Structure
- `docs/` — Generated and maintained documentation (this folder).
- `entrypoint.sh` — GitHub Action entrypoint that builds prompts and invokes Codex CLI.

Notes
- Approval behavior is now determined by the Codex CLI default since `--approval` is not passed.
- TODO: Confirm the default approval mode used by the Codex CLI when `--approval` is omitted.

