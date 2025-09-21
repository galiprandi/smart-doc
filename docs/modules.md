# Modules

Last updated: 2025-09-21T05:23:25Z

This page lists the main scripts and folders and their responsibilities based on the repository contents.

- `action.yml` — Composite GitHub Action metadata and inputs; defines environment variables passed to the entrypoint.
- `smart-doc.sh` — Entrypoint and orchestrator. Key responsibilities:
  - Validate inputs (`OPENAI_API_KEY`, `MODEL` defaults)
  - Ensure Codex CLI (`codex`) is installed (attempts `npm install -g @openai/codex`)
  - Run the LLM with prompt files (uses `prompts/docs.md` by default)
  - Log the `docs/` folder contents
- `prompts/` — Prompt templates used by the LLM. Present files:
  - `prompts/docs.md` — main generation instructions (mirrors expectations for the agent)
  - `prompts/timeline.md` — timeline entry template
- `SMART_TIMELINE.md` — timeline file (present at repo root). The repository contains strict spacing rules for timeline entries (append-only, exactly one blank line between entries).

Where generation happens

- The code delegates actual doc creation to an external LLM CLI (`codex`). The repository contains the prompts and the orchestration; generated files are expected to appear under `docs/` (by the CLI process).

