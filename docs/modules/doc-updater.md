# Doc Updater

## Purpose
Runs the Codex CLI with the built prompt to update documentation under `docs/`, and signals whether any changes were made.

## Key Files
- `scripts/doc-updater.sh`

## Behavior
- Strict Bash mode (`set -euo pipefail`).
- Inputs:
  - `INPUT_DOCS_FOLDER` (default: `docs`)
  - `PROMPT_FILE` (default: `tmp/prompt.md`)
  - `INPUT_MODEL` (default: `gpt-5-nano`)
- Model selection:
  - Exports `OPENAI_MODEL` and `CODEX_MODEL` with the resolved model id.
  - Passes `--model <id>` to the CLI (`code`, `codex`, or `npx @openai/codex`) when supported.
  - Falls back to env‑only if the CLI doesn’t support `--model`.
- Writes concise logs and a change flag at `tmp/have_changes.flag`.

## Outputs
- Updates files under `docs/` when warranted by the prompt/policy.
- Signals changes via `tmp/have_changes.flag` (`yes`/`no`).

## Notable Notes
- Use `INPUT_MODEL` to control cost/perf; `gpt-5-nano` is the default.
- CLI `--dry-run` is a future option if/when exposed; today, previews happen via PR mode.
