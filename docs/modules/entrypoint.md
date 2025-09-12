Module: entrypoint.sh

Purpose
- Orchestrates Smart Doc: determines changed files, builds prompts with diffs, invokes Codex CLI to generate documentation, and commits/pushes results on push events.

Key Responsibilities
- Auth mapping: `SMART_DOC_API_TOKEN` → `OPENAI_API_KEY`.
- Change detection: uses `gh api repos/<repo>/compare/<base>...<head>` or `git ls-files`.
- Prompt assembly: includes file list and unified diffs.
- Generation: prefers local `code` or `codex` binaries, falls back to `npx -y @openai/codex`.
- Commit logic: stages, commits, and pushes doc changes on push events; skips pushes on PRs.

Public Interface (env inputs)
- `INPUT_DOCS_FOLDER` (default: `docs`)
- `INPUT_PROMPT_TEMPLATE` (optional)
- `INPUT_GENERATE_HISTORY` (default: `true`)
- `INPUT_SMART_DOC_API_TOKEN` (required)
- `INPUT_MODEL` (optional; affects the fallback OpenAI Responses API flow)

Important Environment Variables
- `CODEX_SANDBOX=workspace-write` — constrains writes to repository workspace.
- `CODEX_REASONING_EFFORT=medium` — hints reasoning depth to Codex CLI.
 
Notes
- Self‑commit detection and skipping are handled by the workflow layer (not by `entrypoint.sh`).

Dependencies
- External CLIs: `gh`, `jq`, `git`, and one of `code`/`codex`/`node+npx`.
- Services: OpenAI Codex CLI (local or via `npx`), OpenAI Responses API (fallback path).

Risks
- Fallback to `npx` requires network access to install/execute `@openai/codex` if not cached.

TODOs
- Provide guidance for users who need a specific approval mode (if required).
