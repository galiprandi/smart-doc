Architecture Overview

Goals and qualities
- Change‑only, English documentation that is idempotent and scoped to diffs.
- Safe PR workflow for protected branches with optional auto‑merge.
- Minimal dependencies, readable Bash, clear logs.

Main flow (updated)
- Determine change range (push/PR) and build a prompt with file diffs.
- Generate docs via Codex/OpenAI; write only under `docs/` (and optionally `SMART_TIMELINE.md`).
- Create branch `smart-doc/docs-update-<short-sha>` and push.
- Bootstrap `gh` auth non‑fatally using `GH_TOKEN` or `GITHUB_TOKEN`.
- Compute `REPO_SLUG` and call `gh pr create --repo <slug>`; if it fails, try `gh pr list --repo <slug>` to reuse an existing PR.
- Attempt `gh pr merge --repo <slug> --auto --squash` when allowed.

Notable decisions
- Explicit `--repo` passed to all PR operations for reliability in CI.
- Token precedence for `gh`: `GH_TOKEN` (if provided) else `GITHUB_TOKEN`.
- Warnings guide users to fix permissions or supply `GH_TOKEN` when PR creation is blocked.

