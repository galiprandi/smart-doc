Stack and Services

- Language/runtime: Bash on Ubuntu GitHub Actions runners.
- Action type: Composite GitHub Action (`action.yml`).
- Core script: `entrypoint.sh`.
- External CLI: GitHub CLI (`gh`) for compare/PR/merge operations.
- API: OpenAI Responses API (via `OPENAI_API_KEY`).

Tokens and permissions
- `SMART_DOC_API_TOKEN` (required): mapped to `OPENAI_API_KEY` for generation.
- `GITHUB_TOKEN` (default for `gh`): requires job permissions `contents: write` and `pull-requests: write`.
- `GH_TOKEN` (optional): Personal Access Token; set when org policy restricts `GITHUB_TOKEN`.

Environment requirements
- GitHub-hosted runner with `gh`, `git`, `jq`, `curl`, and `bash` available.
- Network access to GitHub API and OpenAI API.

