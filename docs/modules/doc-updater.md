# Doc Updater

## Purpose
Runs the Codex CLI with the built prompt to update documentation under `docs/`, and signals whether any changes were made.

## Key Files
- `scripts/doc-updater.sh`

## Behavior (as of this commit)
- Strict Bash mode (`set -euo pipefail`).
- Inputs:
  - `INPUT_DOCS_FOLDER` (default: `docs`)
  - `PROMPT_FILE` (default: `tmp/prompt.md`)
  - `INPUT_MODEL` (default: `gpt-5-nano`)
- Emits logs with a consistent prefix for traceability.

## Notable Notes
- Contains a minor note about a future `--dry-run` at the LLM level (today handled downstream), indicating planned improvements without behavior change.

## Outputs
- Updates files under `docs/` when warranted by the prompt/policy.
- Signals changes via `tmp/have_changes.flag` (created downstream by the orchestrator).

## TODO
- Add first-class `--dry-run` support when the underlying CLI exposes it.

