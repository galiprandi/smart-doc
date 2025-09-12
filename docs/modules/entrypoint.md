Module: entrypoint.sh

Purpose
- Orchestrates Smart Doc end‑to‑end: gather diffs, build prompt, invoke generation, write docs, and manage PRs.

Key responsibilities (delta)
- Bootstrap GitHub CLI auth using `GH_TOKEN` or `GITHUB_TOKEN` (non‑fatal if absent, but PRs require one).
- Resolve `REPO_SLUG` from `GITHUB_REPOSITORY` or `git remote` and pass `--repo` to `gh` for all PR operations.
- Create or reuse PR: try `gh pr create`, fall back to `gh pr list` when creation fails.
- Attempt auto‑merge (squash) with `gh pr merge --repo <slug> --auto --squash` when allowed.
 - Safely manage the docs update branch `smart-doc/docs-update-<short-sha>`: `git fetch --prune origin`; if `origin/<branch>` exists, `git checkout -B` from it, else create new; push, and on non fast‑forward failure, retry with `--force-with-lease`.

Inputs and env
- `SMART_DOC_API_TOKEN` (required): mapped to `OPENAI_API_KEY`.
- `GH_TOKEN` (optional) or `GITHUB_TOKEN`: used by `gh`.
- `INPUT_BRANCH` (default `main`): PR target.
- `INPUT_DOCS_FOLDER` (default `docs`), `INPUT_PROMPT_TEMPLATE` (optional), `INPUT_GENERATE_HISTORY`.

Outputs
- Files under `docs/` updated/created.
- Branch `smart-doc/docs-update-<short-sha>` with commits.
- PR opened or reused; optional auto‑merge queued.

Risks and notes
- Missing permissions on tokens will block PR operations; warnings advise setting job permissions or providing `GH_TOKEN`.
- Passing `--repo` avoids ambiguity in multi‑remote environments on CI.
 - Using `--force-with-lease` only as a fallback reduces risk of overwriting remote work while still recovering from non fast‑forward situations.

TODO
- Surface `gh` auth/permission failures earlier in logs for faster diagnosis.
