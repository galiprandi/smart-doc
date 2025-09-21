# Stack & Runtime

Last updated: 2025-09-21T05:23:25Z

This file lists runtime expectations and dependencies directly observable in the repository.

- Runtime: Bash scripts as the orchestration layer (`smart-doc.sh`). Scripts assume a POSIX shell (`bash`) with `set -euo pipefail`.
- External tooling invoked by scripts:
  - Node / npm (used to install `@openai/codex` globally when `codex` is not available).
  - `codex` CLI (the LLM client). The script expects it to be available on PATH or installs it via `npm`.
  - `gh` (GitHub CLI) is referenced in AGENTS.md and used by the publisher flow in other scripts, though not invoked directly in `smart-doc.sh`.

- GitHub Action environment:
  - `action.yml` passes `OPENAI_API_KEY` and `MODEL` to `smart-doc.sh`.
  - Action requests `contents: write` and `pull-requests: read` permissions.

Notes and portability

- The entrypoint installs `@openai/codex` globally when `codex` is missing; runners must have `npm` available for that path to succeed.
- The repository includes a minimal timeline file `SMART_TIMELINE.md` and prompt templates for both docs and timeline entries.

