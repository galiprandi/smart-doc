Smart Doc — Internal Docs

Purpose
- Auto-generate concise, change-driven docs from each commit’s diff.
- Write only under `docs/` and optionally append to `SMART_TIMELINE.md`.

What changed in this update
- README refined: emphasizes PR-based updates for protected branches; adds required job permissions.
- New `USAGE.md` with triggers, auth options, and merge orchestration inputs.
- Inputs added/confirmed for merge control: `merge_mode`, `merge_wait_seconds`, `merge_max_attempts`, `ready_pr_if_draft`.

Quickstart
- See top-level `README.md` for the minimal workflow.
- See `USAGE.md` for recipes (GitFlow, PR-only, monorepo paths) and troubleshooting.

Folder structure (docs)
- `docs/README.md` — this page.
- `docs/stack.md` — tooling, tokens, and external services.
- `docs/architecture/overview.md` — flow and decisions.
- `docs/architecture/diagram.md` — Mermaid overview.
- `docs/modules/entrypoint.md` — `entrypoint.sh` responsibilities and interfaces.

