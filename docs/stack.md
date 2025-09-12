Stack and Tooling

Languages and runtime
- Bash on Ubuntu GitHub-hosted runners.

Key tools
- `gh` (GitHub CLI): compare commits, create/edit PRs, enable auto‑merge.
- `curl`: call the OpenAI Responses API and optional Jira REST API.
- `jq`: parse JSON responses.
- `rg` (ripgrep): extract ticket keys from commit messages and PR titles.
- Coreutils: `sed`, `paste`, `grep`, `date`, `mktemp`.

External services
- OpenAI Responses API (via `SMART_DOC_API_TOKEN` -> `OPENAI_API_KEY`).
- GitHub API (through `gh`).
- Optional: Jira Cloud REST API for ticket enrichment when configured.

Environment requirements
- Secrets: `SMART_DOC_API_TOKEN` (required).
- Optional Jira inputs: `INPUT_JIRA_HOST`, `INPUT_JIRA_EMAIL`, `INPUT_JIRA_API_TOKEN` for title/status enrichment in `SMART_TIMELINE.md`.

