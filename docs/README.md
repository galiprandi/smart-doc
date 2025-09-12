Smart Doc — Internal Docs

Purpose
- Auto‑generate concise, change‑driven docs from each commit’s diff.
- Write only under `docs/` and optionally append to `SMART_TIMELINE.md`.

What changed in this update
- GitHub CLI auth is bootstrapped using `GH_TOKEN` (preferred when provided) or `GITHUB_TOKEN`.
- PR operations explicitly pass `--repo <owner/repo>` to `gh` for reliability.
- PR merge step also uses `--repo`; warnings improved when tokens/permissions are missing.
- House workflow now uses the local action path `./` (instead of `galiprandi/smart-doc@v1`) to run the checked‑out action for self‑testing.

Quickstart
- Secret: `SMART_DOC_API_TOKEN` (exported to `OPENAI_API_KEY`).
- Optional: provide `GH_TOKEN` if not relying on `GITHUB_TOKEN` permissions.
- Typical workflow step:
  - `uses: galiprandi/smart-doc@v1`
  - `with.smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}`
  - Optionally: `env.GH_TOKEN: ${{ secrets.GH_PAT }}`
  - Note: In this repository’s CI, we use `uses: ./` to execute the local action during development/testing.

Runtime behavior (relevant parts)
- Creates branch `smart-doc/docs-update-<short-sha>` and pushes it.
- Creates or reuses a PR targeting `branch` (default `main`) using `gh pr create --repo <slug>`.
- Attempts auto‑merge (squash) via `gh pr merge --repo <slug> --auto --squash` when allowed.

Folder structure (docs)
- `docs/README.md` — this page.
- `docs/stack.md` — tooling, tokens, external services.
- `docs/architecture/overview.md` — flow and decisions.
- `docs/architecture/diagram.md` — Mermaid overview.
- `docs/modules/entrypoint.md` — `entrypoint.sh` responsibilities and interfaces.
