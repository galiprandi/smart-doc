# Architecture Overview

- Goals: predictable docs generation, minimal churn, faithful to code changes.
- Key components:
- Diff Detector: identifies changed files and outputs `tmp/changed_files.txt` and `tmp/patch.diff`.
- Prompt Builder: assembles a prompt from templates and diffs (not performing diff itself).
- Doc Updater: runs Codex CLI to produce docs in `docs/` and marks changes via `tmp/have_changes.flag`.
- Publisher: opens a PR on push events if docs changed; no-op on PRs.

- Quality attributes: idempotent diffs, change-scoped docs, safe file writes.

