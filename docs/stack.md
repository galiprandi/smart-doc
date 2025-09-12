Tech Stack

Languages and Runtimes
- Shell (Bash) — primary orchestration in `entrypoint.sh`.

CLIs and Libraries
- OpenAI Codex CLI (`code`/`codex`/`@openai/codex` via `npx`) — generates documentation from prompts.
- `gh` (GitHub CLI) — computes changed files/diffs for context.
- `jq` — JSON extraction for prompt assembly and response parsing.
- `curl` — used by the fallback OpenAI Responses API path.
 - `actions/upload-artifact` — publishes docs preview on PRs.

Environment and Variables
- `SMART_DOC_API_TOKEN` — required; mapped to `OPENAI_API_KEY`.
- `OPENAI_API_KEY` — used if provided; must match `SMART_DOC_API_TOKEN` when both are set.
- `CODEX_SANDBOX=workspace-write` — constrains Codex writes to the repo workspace.
- `CODEX_REASONING_EFFORT=medium` — hint to Codex CLI for reasoning depth.

External Services
- OpenAI Codex CLI (local binary or via `npx`).
- OpenAI Responses API (fallback path).

Provider Compatibility
- Primary: OpenAI (Codex/GPT‑5).
- Adaptable: Qwen/Qwen‑Code. TODO: Document configuration if/when adopted.

Build/Test Tooling
- GitHub Actions runtime executes `entrypoint.sh`.
- Git stages/commits/pushes generated docs on push events; PRs skip push and upload a preview artifact.

Requirements
- Runner tools: `gh`, `jq`, `git`, and at least one of `code`, `codex`, or `node + npx`.
- Network access to OpenAI endpoints and for `npx @openai/codex` when needed.

Notes
- TODO: If alternative providers are configured (e.g., Qwen/Qwen‑Code), document setup.
