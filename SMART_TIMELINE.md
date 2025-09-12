## Migrated timeline file name
- Date: 2025-09-12
- PR: #0
- Commit: INIT
- Tickets: 
- Scope: repo
- TL;DR: Renamed HISTORY.md to SMART_TIMELINE.md and updated references across prompts, README, workflow, and agent guidance.

## GH auth and repo-scoped PR handling
- Date: 2025-09-12
- PR: #0
- Commit: c9084ed
- Tickets: 
- Scope: entrypoint.sh, README.md, .github/workflows/smart-doc.yml
- TL;DR: Bootstrap gh auth (GH_TOKEN/GITHUB_TOKEN), use explicit --repo for PR create/list/merge, and document optional GH_TOKEN usage.

## Use local action path in workflow
- Date: 2025-09-12
- PR: #0
- Commit: a061e99
- Tickets: 
- Scope: .github/workflows/smart-doc.yml
- TL;DR: Switch workflow to `uses: ./` to run the local action for self-testing.
