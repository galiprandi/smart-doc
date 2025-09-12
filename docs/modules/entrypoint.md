Module: entrypoint.sh

Purpose
- Orchestrates Smart Doc: determines changed files, builds prompts with diffs, invokes Codex CLI to generate documentation, and on push events creates a docs update branch and opens an auto‑merge PR to the target branch.

Key Responsibilities
- Auth mapping: `SMART_DOC_API_TOKEN` → `OPENAI_API_KEY`.
- Change detection: uses `gh api repos/<repo>/compare/<base>...<head>` or `git ls-files`.
- Prompt assembly: includes file list and unified diffs.
- Generation: prefers local `code` or `codex` binaries, falls back to `npx -y @openai/codex`.
- Commit logic: stages and commits doc changes; on push events, creates an update branch and opens a PR (attempts auto‑merge); on PR events, skips pushing.

Public Interface (env inputs)
- `INPUT_BRANCH` (default: `main`) — target branch; corresponds to action input `branch`.
- `INPUT_DOCS_FOLDER` (default: `docs`)
- `INPUT_PROMPT_TEMPLATE` (optional)
- `INPUT_GENERATE_HISTORY` (default: `true`)
- `INPUT_SMART_DOC_API_TOKEN` (required)
- `INPUT_MODEL` (optional; affects the fallback OpenAI Responses API flow)

Important Environment Variables
- `CODEX_SANDBOX=workspace-write` — constrains writes to repository workspace.
- `CODEX_REASONING_EFFORT=medium` — hints reasoning depth to Codex CLI.
- Removed in this commit: `CODEX_APPROVAL` is no longer exported or used.

Behavior Change (This Commit)
- Switch from direct `git push` to PR‑based updates on push events using `gh pr create` and `gh pr merge --auto --squash`.
- The `--approval` flag remains removed; approval behavior follows Codex CLI defaults.

Dependencies
- External CLIs: `gh`, `jq`, `git`, and one of `code`/`codex`/`node+npx`.
- Services: OpenAI Codex CLI (local or via `npx`), OpenAI Responses API (fallback path).

Risks
- Unknown default approval behavior may surprise users expecting explicit `never` behavior.
- Fallback to `npx` requires network access to install/execute `@openai/codex` if not cached.
- PR creation/auto‑merge requires `pull-requests: write`; lack of permission will skip PR or auto‑merge.

TODOs
- Confirm and document the default approval policy of Codex CLI when `--approval` is omitted.
- Provide guidance for users who need a specific approval mode.
