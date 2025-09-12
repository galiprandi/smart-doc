Smart Doc — Internal Documentation

- Purpose: Generate change-driven documentation on every integration by turning commit diffs into concise pages under `docs/` and optional timeline entries in `SMART_TIMELINE.md`.
- Scope: Documentation only. Never edits application code.

Quickstart
- Add the GitHub Action using `uses: galiprandi/smart-doc@v1`.
- Provide `SMART_DOC_API_TOKEN` (exported as `OPENAI_API_KEY`).
- Ensure GitHub CLI (`gh`) can authenticate to open PRs:
  - Prefer `GITHUB_TOKEN` with job permissions: `permissions.contents: write` and `permissions.pull-requests: write`.
  - Or set `GH_TOKEN` from a PAT secret with minimal scopes (e.g., `repo`).

PR Behavior
- Creates a branch named `smart-doc/docs-update-<short-sha>` and opens a PR; never pushes directly to protected branches.
- On PR events, does not push changes; provides previews or summaries as configured.

Troubleshooting `gh`
- If PR creation fails, verify job permissions, that a token is available to `gh` (`GITHUB_TOKEN` or `GH_TOKEN`), and that `gh auth status` succeeds in logs.

Folder Structure
- `docs/` — Generated docs (this folder).
- `SMART_TIMELINE.md` — Append-only change timeline (optional, one blank line between entries).
- Key repo files (for reference): `action.yml`, `entrypoint.sh`, `prompts/default.md`.

Internal Links
- Stack: `docs/stack.md`
- Architecture overview: `docs/architecture/overview.md`
- Architecture diagram: `docs/architecture/diagram.md`

