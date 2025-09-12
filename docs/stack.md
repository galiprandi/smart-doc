Stack and Services

- Language/runtime: Bash on Ubuntu GitHub Actions runners.
- Action type: Composite GitHub Action (`action.yml`).
- Core script: `entrypoint.sh`.
- External CLI: GitHub CLI (`gh`) for compare/PR/merge operations.
- API: OpenAI Responses API (via `OPENAI_API_KEY`).
 - Git operations: `fetch --prune`, branch create/reset, and guarded `push --force-with-lease` fallback when non fast-forward.

Tokens and permissions
- `SMART_DOC_API_TOKEN` (required): mapped to `OPENAI_API_KEY` for generation.
- `GH_TOKEN` (optional): Personal Access Token for `gh`; takes precedence when set.
- `GITHUB_TOKEN`: fallback for `gh` when `GH_TOKEN` is not provided; requires job permissions `contents: write` and `pull-requests: write`.

Environment requirements
- GitHub‑hosted runner with `gh`, `git`, `jq`, `curl`, and `bash` available.
- Network access to GitHub API and OpenAI API.
