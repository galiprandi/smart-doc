Overview

Goals
- Generate concise, change-scoped documentation based on Git diffs.
- Keep docs additive and idempotent; avoid unrelated churn.

Key Flow
- Detect changed files via GitHub context (`gh api` for compares).
- Build a structured prompt, including unified diffs.
- Invoke Codex CLI with `CODEX_SANDBOX=workspace-write` and `CODEX_REASONING_EFFORT=medium`.
- Fallback to `npx -y @openai/codex` if local binaries aren’t present.
- On push events, commit and push any doc changes; on PR events, skip pushing and optionally comment a summary.

Notable Decision (This Commit)
- Removed explicit approval handling: `CODEX_APPROVAL` env var and the `--approval` CLI flag were deleted. Approval behavior now follows the Codex CLI default when invoking `exec`.

Quality Attributes
- Safety: Workspace-write sandbox limits write scope to the repository.
- Traceability: Diffs are embedded into the prompt for precise context.
- Predictability: Push events auto-commit; PRs avoid writes to the target branch.

Open Questions
- TODO: Clarify the Codex CLI default approval mode when `--approval` is omitted and document any ways to configure it if needed.

