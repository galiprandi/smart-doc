Smart Doc — Internal Docs (change-focused)

Purpose
- Smart Doc is a composite GitHub Action that turns commit diffs into concise, English docs under `docs/` and maintains an append-only `SMART_TIMELINE.md`.

What changed in this iteration
- The action now appends a timeline entry to `SMART_TIMELINE.md` on the PR branch and adds a preview block to the PR body.
- Ticket keys referenced in the commit message or PR title (e.g., ABC-123) are detected; optional Jira enrichment adds title and status when Jira credentials are provided.

Quickstart (reference)
- Add to a workflow: `uses: galiprandi/smart-doc@v1`.
- Required secret: `SMART_DOC_API_TOKEN` (maps to `OPENAI_API_KEY`).
- Output: updated files under `docs/` and a PR `smart-doc/docs-update-<short-sha>` with auto‑merge enabled when allowed.

Folder structure (docs)
- `docs/README.md` — this page.
- `docs/stack.md` — runtime tools and external services.
- `docs/architecture/overview.md` — goals and flows.
- `docs/architecture/diagram.md` — Mermaid diagram.
- `docs/modules/timeline.md` — SMART_TIMELINE append logic.

Related
- Social copy for launches: see `SOCIAL_COPY.md` at repo root.

