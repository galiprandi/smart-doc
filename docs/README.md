# Smart Doc — Documentation

This folder hosts Smart Doc’s internal documentation. See `AGENTS.md` at the repository root for guardrails and contributor guidelines.

- Agent contributors: see `AGENTS.md` for scope and editing rules.
- Docs scope: change‑driven, English‑only, minimal churn.
- Output location: generated pages live under `docs/`.

## Workflows
- Push + PR (default): updates docs on pushes to `main` (with anti‑loop and `paths-ignore`) and previews on PRs.
- PR‑only previews: supported for repos that only want safe previews on pull requests. See `README.md` for the “PR-only workflow example (no pushes, safe previews)`, including `concurrency` and `actions/checkout@v4` with `fetch-depth: 0`.

- Monorepo selective (paths filters): scope Smart Doc runs to specific subfolders (e.g., `apps/frontend/**`, `packages/ui/**`). Keep `paths-ignore` for `docs/**` and `SMART_TIMELINE.md`, preserve the anti‑loop job condition, and set `concurrency.cancel-in-progress: true`. See `README.md` for the full “Monorepo selective (paths filters) — example” YAML.

## Outputs
- Generated docs live under `docs/` and are scoped to the latest commit diff.
- Timeline: optional `SMART_TIMELINE.md` at the repo root (append‑only). Format fields: Date (YYYY‑MM‑DD), PR, Commit (short‑sha), Tickets (optional), Scope (areas/paths), TL;DR. Separation: exactly one blank line between entries; end with a trailing newline. Controlled by input `generate_history`.
- Anti‑loop snippet: include `docs/**` and `SMART_TIMELINE.md` in `paths-ignore` on push jobs.

TODO: Expand module and architecture docs as code changes introduce or modify components.
