Architecture Overview

Goals and qualities
- Change-only, English documentation that is idempotent and scoped to diffs.
- Safe PR workflow for protected branches with optional auto-merge.
- Minimal dependencies, readable Bash, clear logs.

Main flow (current)
- Determine change range (push/PR) and collect diffs via `gh api repos/<slug>/compare/<base>...<head>`.
- Build a prompt (default `prompts/default.md` unless overridden) and call Codex/OpenAI.
- Write only under `docs/` (and optionally append `SMART_TIMELINE.md`).
- Create/update branch `smart-doc/docs-update-<short-sha>` and push.
- Use `gh pr create --repo <slug>` or reuse an existing PR if already open.
- Merge orchestration via inputs:
  - `merge_mode`: `auto` (queue auto-merge), `immediate` (wait until mergeable then squash), or `off`.
  - `merge_wait_seconds`, `merge_max_attempts`, `ready_pr_if_draft` for readiness and polling.

Notable decisions
- Always pass `--repo <owner/repo>` to `gh` for reliability on CI.
- Default auth for `gh` uses `GITHUB_TOKEN` (with permissions); `GH_TOKEN` PAT is optional.
- Append a timeline entry and include a preview in the PR body when available.

