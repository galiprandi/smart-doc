Module: Timeline Append (SMART_TIMELINE.md)

Purpose
- Append a formatted, append‑only entry to `SMART_TIMELINE.md` on the PR branch and add a preview to the PR body.

Responsibilities
- Compute `Scope` by listing changed paths under `docs/` in the last commit on the update branch.
- Extract ticket keys (pattern like `ABC-123`) from the commit message and PR title using `rg`.
- Optionally enrich each ticket via Jira (title and status) when `INPUT_JIRA_HOST`, `INPUT_JIRA_EMAIL`, and `INPUT_JIRA_API_TOKEN` are set.
- Build the entry with fields: Date, PR, Commit, Tickets, Scope, TL;DR (English); ensure single‑blank‑line separation.
- Commit and push the updated timeline to `smart-doc/docs-update-<short-sha>` and edit the PR body with a preview block.

Key file(s)
- `entrypoint.sh` — timeline assembly, Jira enrichment helper, PR body update.

Dependencies
- `gh`, `curl`, `jq`, `rg` (ripgrep), and shell utilities (`sed`, `paste`, `date`, `mktemp`).

Public behavior
- `SMART_TIMELINE.md` gains a new entry per documentation update PR, and the PR description includes a “Docs Timeline Entry (preview)”.

Risks
- Missing tools (`rg`, `jq`, `curl`) would limit extraction/enrichment; the script guards operations and degrades gracefully.
- Jira enrichment requires credentials; without them, raw keys are shown.

TODO
- Consider optional ClickUp enrichment (`INPUT_CLICKUP_TOKEN`) for parity with Jira.

