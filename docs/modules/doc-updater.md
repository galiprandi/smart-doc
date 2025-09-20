# Module: doc-updater

- Purpose: generate docs via Codex CLI using a prepared prompt.
- Key inputs: `PROMPT_FILE`, `MODEL`, `INPUT_DOCS_FOLDER` (default `docs`).
- Outputs: updated docs in `docs/` and a flag file signaling changes.
- Notes: robust to portability (avoids mapfile dependencies).

