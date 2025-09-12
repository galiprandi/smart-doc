Tech Stack

Languages and Runtimes
- Shell (Bash) — primary orchestration in `entrypoint.sh`.

CLIs and Libraries
- Codex CLI (`code`/`codex`/`@openai/codex` via `npx`) — generates documentation from prompts.
- `gh` (GitHub CLI) — computes changed files/diffs for context.
- `jq` — JSON extraction for prompt assembly and response parsing.
- `curl` — used by the fallback OpenAI Responses API path.

Environment and Variables
- `SMART_DOC_API_TOKEN` — required; mapped to `OPENAI_API_KEY`.
- `OPENAI_API_KEY` — used if provided; must match `SMART_DOC_API_TOKEN` when both are set.
- `CODEX_SANDBOX=workspace-write` — ensures Codex can write into the repository workspace.
- `CODEX_REASONING_EFFORT=medium` — provides a hint to Codex CLI for reasoning depth.
- Removed: `CODEX_APPROVAL` — approval mode is no longer explicitly set.

External Services
- OpenAI Codex CLI (local binary or via `npx`).
- OpenAI Responses API (fallback path).

Build/Test Tooling
- GitHub Actions runtime executes `entrypoint.sh`.
- Git is used to stage/commit/push generated docs on push events.

Requirements
- Tools available in the runner: `gh`, `jq`, `git`, and at least one of `code`, `codex`, or `node + npx`.
- Network access to OpenAI endpoints and to fetch `@openai/codex` via `npx` if needed.

Notes
- Approval behavior for Codex CLI now relies on its default since `--approval` is not provided.
- TODO: Document Codex CLI’s default approval behavior and how to override it if necessary.

