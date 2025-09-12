# Smart Doc — Documentation

This folder hosts Smart Doc’s internal documentation. See `AGENTS.md` at the repository root for guardrails and contributor guidelines.

- Agent contributors: see `AGENTS.md` for scope and editing rules.
- Docs scope: change‑driven, English‑only, minimal churn.
- Output location: generated pages live under `docs/`.

## Workflows
- Push + PR (default): updates docs on pushes to `main` (with anti‑loop and `paths-ignore`) and previews on PRs.
- PR‑only previews: supported for repos that only want safe previews on pull requests. See `README.md` for the “PR-only workflow example (no pushes, safe previews)`, including `concurrency` and `actions/checkout@v4` with `fetch-depth: 0`.

- Monorepo selective (paths filters): scope Smart Doc runs to specific subfolders (e.g., `apps/frontend/**`, `packages/ui/**`). Keep `paths-ignore` for `docs/**` and `HISTORY.md`, preserve the anti‑loop job condition, and set `concurrency.cancel-in-progress: true`. See `README.md` for the full “Monorepo selective (paths filters) — example” YAML.

TODO: Expand module and architecture docs as code changes introduce or modify components.
