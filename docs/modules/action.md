Module: action.yml

Purpose
- Defines the Smart Doc composite action interface and runtime behavior.

Responsibilities
- Declares inputs (branch, docs folder, prompt, model, history, auth, optional ticket vars).
- Installs OpenAI Codex CLI if missing and invokes `entrypoint.sh`.
- Sets permissions for repo write (contents) and PR read.

Public Inputs
- `smart_doc_api_token` (required): API key alias; exported as `OPENAI_API_KEY`.
- `branch` (default: `main`): reference branch for change comparison.
- `docs_folder` (default: `docs`): destination for generated docs.
- `prompt_template` (optional): path to a custom prompt.
- `model` (default: `gpt-5-nano`): affects fallback OpenAI Responses API usage.
- `generate_history` (default: `true`): allow agent to write `HISTORY.md` when produced.
- Optional enrichment (not required): `jira_host`, `jira_email`, `jira_api_token`, `clickup_token`.

Compatibility
- Primary provider: OpenAI (Codex/GPT‑5).
- Adaptable to Qwen/Qwen‑Code if desired (no built‑in server config here).

Notes
- Uses a composite (`using: composite`); no Docker needed.
- Usage example aligns with `galiprandi/smart-doc@v1` as per README.
- No breaking input changes in this commit; description updated to reflect provider‑agnostic positioning.

TODO
- Document a Qwen/Qwen‑Code configuration path if adopted.
