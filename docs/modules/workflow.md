Module: GitHub Workflow (test.yml)

Purpose
- Define when Smart Doc runs and grant required repository permissions.

Key Responsibilities
- Trigger on changes to the target branch (e.g., `main`).
- Provide the GitHub token to the action.
- Set permissions so the action can write contents and manage pull requests.

Permissions (Updated)
- `contents: write`
- `pull-requests: write` (changed from `read`) — required for opening PRs and attempting auto‑merge.

Notes
- Keep `fetch-depth: 0` in `actions/checkout` so full history is available for diffs.
- Example minimal workflow shows the `permissions` block at the top level.

TODO
- Clarify any additional scopes if organization policies restrict PR auto‑merge.

