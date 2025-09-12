Stack and Dependencies

- Languages/Runtime: Bash (composite GitHub Action), runs on `ubuntu-latest`.
- Core tooling: GitHub CLI (`gh`) for creating PRs; Codex CLI for generation; Git.
- Secrets/Tokens:
  - `SMART_DOC_API_TOKEN` (exported as `OPENAI_API_KEY`) — model access for generation.
  - `GITHUB_TOKEN` with permissions `contents: write` and `pull-requests: write`, or `GH_TOKEN` from a PAT — used by `gh` to open PRs.
- External services: GitHub API via `gh`.
- Inputs (via `action.yml`): `branch`, `docs_folder`, `prompt_template`, `model`, `generate_history`.
- Output: Markdown files under `docs/` and optional entries in `SMART_TIMELINE.md`.

Environment Requirements
- `gh` available on the GitHub-hosted runner (preinstalled on `ubuntu-latest`).
- Network access to reach the model provider (via `SMART_DOC_API_TOKEN`).

Notes
- Smart Doc never pushes directly to protected branches; it always opens a PR from `smart-doc/docs-update-<short-sha>`.
- If `gh pr create` fails, confirm token availability and job permissions.

