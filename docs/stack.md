# Stack and Runtime

Last updated: 2025-09-21T05:29:20Z

Runtime
- Bash scripts (POSIX-compatible, strict mode `set -euo pipefail`).
- Requires Node/npm for optional global install of `@openai/codex` when the CLI is not present.

Dependencies
- `@openai/codex` (LLM CLI) — recommended to be installed in the runner environment or available via `codex` command.
- `gh` (GitHub CLI) — used by the publisher in full pipeline flows for opening PRs (not strictly required by minimal `smart-doc.sh` but referenced in docs and AGENTS.md).

Inputs and Secrets
- Required secret: `OPENAI_API_KEY` (exported into the action's environment).
- Optional input: `model` (default set in `action.yml` to `gpt-5-mini`).

Permissions (from `action.yml`)
- `contents: write`
- `pull-requests: read`

Notes
- `AGENTS.md` contains extended guidance (Jira MCP, Qwen provider notes, anti-loop workflow snippets, and local Docker development instructions).
- For local development the repository provides helper scripts described in `AGENTS.md`.

