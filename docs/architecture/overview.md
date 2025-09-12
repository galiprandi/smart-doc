Architecture Overview

Goals
- Generate change‑only documentation in English under `docs/`.
- Propose updates via PR to protect default branches; enable auto‑merge when permitted.
- Maintain an append‑only `SMART_TIMELINE.md` with one‑line summaries per update.

Main flow (relevant to this change)
- After generating docs and creating the PR `smart-doc/docs-update-<short-sha>`, the action:
  - Computes the docs scope changed in the last commit on the PR branch.
  - Extracts ticket keys (e.g., `ABC-123`) from the commit message and PR title.
  - Optionally enriches each ticket with Jira title/status when Jira inputs are provided.
  - Appends a formatted entry to `SMART_TIMELINE.md` and pushes to the PR branch.
  - Updates the PR body with a “Docs Timeline Entry (preview)” block.

Notable decisions
- Timeline entries are appended on the PR branch (not deferred until merge) to keep the PR self‑describing.
- Jira enrichment is strictly optional and gated by inputs (`INPUT_JIRA_HOST`, `INPUT_JIRA_EMAIL`, `INPUT_JIRA_API_TOKEN`).
- Branch naming for generated updates is fixed: `smart-doc/docs-update-<short-sha>`.

