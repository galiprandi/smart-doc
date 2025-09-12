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
 - CI guardrails: GitHub Actions `concurrency` gate cancels in‑progress runs per workflow/ref to avoid overlaps.
 - Triggers: Configurable to run on `main`, `develop`, `release/*`, and/or `pull_request` events.

Positioning Update (This Commit)
- Clarified product positioning: “living documentation” with provider‑agnostic design — OpenAI first‑class, adaptable to Qwen/Qwen‑Code.
- Public usage updated to `galiprandi/smart-doc@v1`.

CI Triggers and Concurrency (This Commit)
- Added a `concurrency` group (`smart-doc-${{ github.workflow }}-${{ github.ref }}`) with `cancel-in-progress: true` in workflow examples and tests.
- Documented customizable triggers (GitFlow `develop`, `release/*`, trunk `main`, and PRs) with optional `paths-ignore` for docs artifacts.

Quality Attributes
- Safety: Workspace-write sandbox limits write scope to the repository.
- Traceability: Diffs are embedded into the prompt for precise context.
- Predictability: Push events auto-commit; PRs avoid writes to the target branch.

Open Questions
- TODO: Document Qwen/Qwen‑Code setup if adopted.
- TODO: Clarify Codex CLI default approval mode when `--approval` is omitted and how to override it if needed.
