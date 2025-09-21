# Modules

Last updated: 2025-09-21T05:34:47Z  (commit `f01f43b`)

Key components in the repository:

- `action.yml` — composite action metadata and inputs (model, provider, etc.).
- `entrypoint.sh` / `smart-doc.sh` — orchestrator and minimal fallback mode (timeline append).
- `scripts/validator.sh` — environment and preflight checks (API key, tools, template).
- `scripts/diff-detector.sh` — determines changed files and produces a unified diff.
- `scripts/prompt-builder.sh` — constructs the final prompt from the diffs and templates.
- `scripts/doc-updater.sh` — runs the Codex CLI (workspace-write) with the prompt and writes docs to `docs/`.
- `scripts/publisher.sh` — opens a PR using `gh` (no-op on pull_request events).
- `prompts/` — prompt templates used to instruct the model (`docs.md`, `timeline.md`).

Runtime behavior summary:
- On push events: full pipeline runs and, if docs changed, `publisher.sh` creates a PR on a branch named `smart-doc/docs-update-<sha|epoch>`.
- On pull_request events: publishing is skipped by design (the action will not push/PR).
