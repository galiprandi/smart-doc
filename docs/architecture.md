# Architecture

Last updated: 2025-09-21T05:23:25Z

This file summarizes the runtime flow and major components of Smart Doc, based strictly on files present in the repository.

Overview

- The Action is defined in `action.yml` and runs a single composite step that executes `./smart-doc.sh`.
- `smart-doc.sh` is the entrypoint: a small Bash orchestration script (strict mode: `set -euo pipefail`).
- Prompts used for generation live under `prompts/` (e.g. `prompts/docs.md`, `prompts/timeline.md`).

Minimal flow (what actually runs)

```mermaid
flowchart LR
  A[GitHub Action: action.yml] --> B[shell: ./smart-doc.sh]
  B --> C[setup_inputs]
  B --> D[install_codex_globally]
  B --> E[run_llm with prompts/docs.md]
  E --> F[LLM CLI (`codex`) invocation]
  F --> G[docs/ updated by CLI (external)]
  B --> H[log_docs_folder]
```

Notes grounded in code

- `action.yml` passes `OPENAI_API_KEY` and `MODEL` to the script and requests `contents: write` and `pull-requests: read` permissions.
- `smart-doc.sh` currently enforces an API key check (fails if unset or placeholder) and attempts to install `@openai/codex` globally if `codex` is not available.
- The script calls `codex mode exec --full-auto -m gpt-5-mini` piping the prompt content; its success is required for the script to complete.

Appendix

- Prompts: `prompts/docs.md` contains the task instructions the LLM should follow; `prompts/timeline.md` exists for timeline entries.

