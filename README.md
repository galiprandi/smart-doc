# Smart Doc — Auto-document your code with Qwen-Code

Smart Doc is a simple composite GitHub Action that analyzes code changes and updates documentation under `docs/`, optionally enriching it with ticket context and generating `HISTORY.md` in the repo root.

Key points
- Composite action (Bash): minimal and maintainable.
- Uses Qwen-Code CLI; attempts FS tool first, then falls back.
- MCP (Jira/ClickUp) optional via `~/.qwen/settings.json` when secrets are provided.

Usage
1) Add auth secret for Qwen-Code.
   - Preferred: `OPENAI_API_KEY` (recommended; Qwen CLI accepts provider keys).
   - Optional/legacy: `SMART_DOC_API_TOKEN` (kept for backward compatibility; Qwen may ignore it).
   - Add under: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`.
2) Create workflow `.github/workflows/docs.yml`:

```yaml
name: Smart Doc
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  update-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Smart Doc
        uses: your-org/smart-doc@v1
        with:
          smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}
          branch: main
          docs_folder: docs
          generate_history: 'true'
          # Optional MCP integrations
          # jira_host: ${{ secrets.JIRA_HOST }}
          # jira_email: ${{ secrets.JIRA_EMAIL }}
          # jira_api_token: ${{ secrets.JIRA_API_TOKEN }}
          # clickup_token: ${{ secrets.CLICKUP_TOKEN }}
```

Inputs
- `openai_api_key` (optional, recommended): OpenAI API key used by Qwen-Code.
- `smart_doc_api_token` (optional, legacy): kept for compatibility; current Qwen prefers provider keys.
- `branch` (default: `main`): reference branch for diffs.
- `docs_folder` (default: `docs`): documentation directory; created if missing.
- `prompt_template` (optional): path to custom prompt in repo.
- `generate_history` (default: `true`): ensure `HISTORY.md` exists in root.
- Optional MCP: `jira_host`, `jira_email`, `jira_api_token`, `clickup_token`.

How it works
- Computes changed files using `git diff origin/<branch>...HEAD` (or PR base).
- Builds the prompt (custom or default) and appends changed files context.
- Runs `qwen exec` (FS tool first, then fallback variants).
- Commits and pushes only on `push` events (no push on PRs).

Notes on MCP
- MCP (Model Context Protocol) refers to external context providers the agent can query (e.g., Jira/ClickUp). This action only creates `~/.qwen/settings.json` if the related secrets are provided; otherwise it skips MCP entirely.

Secrets
- Preferred:
  - `OPENAI_API_KEY`: Used by Qwen-Code for model access.
- Optional:
  - `SMART_DOC_API_TOKEN`: Legacy token; may not be used by current CLI.
- Optional (only if you want ticket enrichment):
  - `JIRA_HOST` (e.g., `https://your-company.atlassian.net`)
  - `JIRA_EMAIL`
  - `JIRA_API_TOKEN`
  - `CLICKUP_TOKEN`

License
MIT

Test note: Triggering Smart Doc via a minimal change (v3).
