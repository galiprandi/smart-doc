Module: entrypoint.sh

Purpose
- Orchestrates Smart Doc end‑to‑end: gather diffs, build prompt, invoke generation, write docs, and manage PRs.

Key responsibilities (delta)
- Bootstrap GitHub CLI auth using `GH_TOKEN` or `GITHUB_TOKEN` (non‑fatal if absent, but PRs require one).
- Resolve `REPO_SLUG` from `GITHUB_REPOSITORY` or `git remote` and pass `--repo` to `gh` for all PR operations.
- Create or reuse PR: try `gh pr create`, fall back to `gh pr list` when creation fails.
- Ensure PR readiness (optional): convert draft PRs to ready for review.
- Orchestrate merge by mode:
  - `auto`: queue auto‑merge (squash).
  - `immediate`: poll until mergeable, then squash‑merge and delete branch.
  - `off`: leave PR open.

Inputs and env
- `SMART_DOC_API_TOKEN` (required): mapped to `OPENAI_API_KEY`.
- `GH_TOKEN` (optional) or `GITHUB_TOKEN`: used by `gh`.
- `INPUT_BRANCH` (default `main`): PR target.
- `INPUT_DOCS_FOLDER` (default `docs`), `INPUT_PROMPT_TEMPLATE` (optional), `INPUT_GENERATE_HISTORY`.
- Merge orchestration inputs:
  - `INPUT_MERGE_MODE` (default `auto`).
  - `INPUT_MERGE_WAIT_SECONDS` (default `10`).
  - `INPUT_MERGE_MAX_ATTEMPTS` (default `30`).
  - `INPUT_READY_PR_IF_DRAFT` (default `true`).

Outputs
- Files under `docs/` updated/created.
- Branch `smart-doc/docs-update-<short-sha>` with commits.
- PR opened or reused; readiness ensured; merge attempted per configured mode.

Risks and notes
- Missing permissions on tokens will block PR operations; warnings advise setting job permissions or providing `GH_TOKEN`.
- Passing `--repo` avoids ambiguity in multi‑remote environments on CI.
- Immediate mode relies on GitHub PR `mergeable`/`mergeStateStatus`; polling cadence and attempts are configurable.

TODO
- Surface `gh` auth/permission failures earlier in logs for faster diagnosis.
