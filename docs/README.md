# Smart Doc — Documentation

This folder hosts Smart Doc’s internal documentation. See `AGENTS.md` at the repository root for guardrails and contributor guidelines.

- Agent contributors: see `AGENTS.md` for scope and editing rules.
- Docs scope: change‑driven, English‑only, minimal churn.
- Output location: generated pages live under `docs/`.

## Workflows
- Push + PR (default): updates docs on pushes to `main` (with anti‑loop and `paths-ignore`) and previews on PRs.
- PR‑only previews: supported for repos that only want safe previews on pull requests. See `README.md` for the “PR-only workflow example (no pushes, safe previews)`, including `concurrency` and `actions/checkout@v4` with `fetch-depth: 0`.

TODO: Expand module and architecture docs as code changes introduce or modify components.
