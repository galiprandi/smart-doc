Architecture Overview

Goals and Qualities
- Keep project documentation current with each change (diff-driven, English, concise).
- Safe updates: operate via PRs, not direct pushes to protected branches.
- Idempotent generation with minimal churn.

Main Components
- Composite Action (`action.yml`): wires inputs, defaults, and execution on GitHub Actions.
- Entrypoint (`entrypoint.sh`): gathers changed files and diffs, builds prompts, invokes Codex CLI, writes docs, and opens a PR.
- GitHub CLI (`gh`): authenticates using `GITHUB_TOKEN` or `GH_TOKEN` to create PRs from `smart-doc/docs-update-<short-sha>`.
- Docs output: Markdown files under `docs/` and optional timeline entries in `SMART_TIMELINE.md`.

Key Flows
1) Diff collection → prompt assembly → generation → write to `docs//*`.
2) Branch creation `smart-doc/docs-update-<short-sha>` → `gh pr create` → enable auto-merge where allowed.

Notable Decisions
- Use `GITHUB_TOKEN` (with `contents: write` and `pull-requests: write`) for most repositories; allow `GH_TOKEN` from a PAT as fallback.
- Strict formatting for `SMART_TIMELINE.md` (append-only, one blank line between entries).
- Avoid model/provider-specific branches in shell logic; rely on inputs and CLI flags.

Risks and Mitigations
- PR creation failures due to insufficient permissions or missing token → verify permissions and `gh auth status` in logs.
- Overwriting unrelated docs → generation is scoped to changed files and immediate context.

TODO: Elaborate on model provider configuration options if additional providers are introduced.

