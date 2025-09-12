Module: entrypoint.sh

Purpose
- Orchestrates Smart Doc end-to-end: gather diffs, build prompt, invoke generation, write docs, and manage PRs.

Key responsibilities (current)
- Collect changed files/diffs via GitHub API using `gh api repos/<slug>/compare/<base>...<head>`.
- Build prompt from `prompts/default.md` (or custom) and call Codex/OpenAI.
- Write outputs strictly under `docs/` and optionally append to `SMART_TIMELINE.md`.
- Create/update `smart-doc/docs-update-<short-sha>` branch, push, and open or reuse a PR with `--repo`.
- Merge orchestration using inputs:
  - `merge_mode`: `auto` | `immediate` | `off`.
  - `merge_wait_seconds`, `merge_max_attempts`, `ready_pr_if_draft`.
- Add timeline entry to `SMART_TIMELINE.md` and include a preview in the PR body when a PR is available.

Inputs and env
- `SMART_DOC_API_TOKEN` (required): mapped to `OPENAI_API_KEY`.
- `branch` (default `main`): PR target.
- `docs_folder` (default `docs`), `prompt_template` (optional), `model` (optional).
- `merge_mode`, `merge_wait_seconds`, `merge_max_attempts`, `ready_pr_if_draft` (merge controls).
- Auth for `gh`: `GITHUB_TOKEN` by default; optional `GH_TOKEN` PAT.

Outputs
- Files under `docs/` updated/created; optional timeline entry appended.
- Branch `smart-doc/docs-update-<short-sha>` with commits.
- PR opened or reused; auto-merge queued or performed when configured/allowed.

Risks and notes
- Missing token or insufficient permissions will block PR/merge operations; ensure job permissions `contents: write` and `pull-requests: write`.
- Passing `--repo` avoids ambiguity in multi-remote CI environments.

