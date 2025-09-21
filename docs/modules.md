# Modules and Key Scripts

Last updated: 2025-09-21T05:29:20Z

- `smart-doc.sh` — main minimal entrypoint (Bash, strict mode). It:
  - Validates `OPENAI_API_KEY` and `MODEL` (environment inputs).
  - Attempts to install `@openai/codex` CLI if not present.
  - Runs the Codex CLI with `prompts/docs.md` to generate docs.
  - Logs contents of the `docs/` folder if present.

- `action.yml` — composite action metadata. Declares inputs (`model`, `openai_api_key`) and runs `./smart-doc.sh`.

- `prompts/` — contains prompt templates used by the generator:
  - `prompts/docs.md` — instructions for the documentation writer (this file).
  - `prompts/timeline.md` — timeline prompt template.

- `AGENTS.md` — repository guidance for AI agents and guardrails. It documents the fuller pipeline and append-only `SMART_TIMELINE.md` rules.

Files referenced by the generator:
- `SMART_TIMELINE.md` — append-only timeline (empty in repo root).
- `tmp/` — temporary runtime files (created by scripts when used).

