# Smart Doc — Auto-document your code with Qwen-Code

Smart Doc is a simple composite GitHub Action that analyzes code changes and updates documentation under `docs/`, optionally enriching it with ticket context and generating `HISTORY.md` in the repo root.

Key points
- Composite action (Bash): minimal and maintainable.
- Uses Qwen-Code CLI. Default model (por ahora): `openai:gpt-5-nano`.
- MCP (Jira/ClickUp) optional via `~/.qwen/settings.json` when secrets are provided.

Usage
1) Add auth secret for Qwen-Code.
   - SMART_DOC_API_TOKEN = OPENAI_API_KEY. Put your OpenAI key in `SMART_DOC_API_TOKEN`; the action exports it as `OPENAI_API_KEY`.
   - Do NOT define both `SMART_DOC_API_TOKEN` and `OPENAI_API_KEY`. The action will fail if both are set with different values.
   - Where: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`.
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
- `smart_doc_api_token` (required): OpenAI API key alias. Mapped to `OPENAI_API_KEY`.
- `branch` (default: `main`): reference branch for diffs.
- `docs_folder` (default: `docs`): documentation directory; created if missing.
- `prompt_template` (optional): path to custom prompt in repo.
- `generate_history` (default: `true`): ensure `HISTORY.md` exists in root.
- `model` (optional): override model (e.g., `openai:gpt-5-nano`). Por defecto: `openai:gpt-5-nano` (puedes cambiarlo o dejar vacío si prefieres que Qwen elija).
- Optional MCP: `jira_host`, `jira_email`, `jira_api_token`, `clickup_token`.

How it works
- Computes changed files using GitHub API via `gh api repos/<owner>/<repo>/compare/<base>...<head>`.
- Builds the prompt (custom or default) and appends changed files context.
- Uses model set by `model` (default: `openai:gpt-5-nano`).
- Runs `qwen` in non‑interactive mode con `-p` o vía stdin.
- Posts a PR comment summary (on PRs). On `push` events, stages/commits/pushes doc changes.

Notes on MCP
- MCP (Model Context Protocol) refers to external context providers the agent can query (e.g., Jira/ClickUp). This action only creates `~/.qwen/settings.json` if the related secrets are provided; otherwise it skips MCP entirely.

Secrets
- Required:
  - `SMART_DOC_API_TOKEN`: Put your OpenAI API key here (this action exports it as `OPENAI_API_KEY`). Do not also set `OPENAI_API_KEY`.
- Optional (only if you want ticket enrichment):
  - `JIRA_HOST` (e.g., `https://your-company.atlassian.net`)
  - `JIRA_EMAIL`
  - `JIRA_API_TOKEN`
  - `CLICKUP_TOKEN`

License
MIT

Test note: Triggering Smart Doc via a minimal change (v5).
