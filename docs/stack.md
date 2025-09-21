# Stack

Last updated: 2025-09-21T05:34:47Z  (commit `f01f43b`)

Runtime and tools (explicitly referenced in the repository):

- GitHub Actions (composite action via `action.yml`).
- Bash scripts (strict mode; small utilities). The repo prefers portable shells and avoids mapfile to increase portability.
- Codex CLI (invoked by `scripts/doc-updater.sh`). The repo supports multiple providers (OpenAI / Qwen via Ollama) configured via inputs and envs.
- `gh` (GitHub CLI) used by `scripts/publisher.sh` to create PRs and manage branches.
- Optional: Jira MCP configuration written to `~/.codex/config.toml` when `JIRA_EMAIL`, `JIRA_API_TOKEN`, and `JIRA_DOMAIN` are present.

Local development:
- A Dockerfile and `scripts/dev-run-docs.sh` exist to run generation in an Ubuntu environment when needed.
