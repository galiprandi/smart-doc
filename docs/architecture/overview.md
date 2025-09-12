# Architecture Overview

## Goals and Quality Attributes
- Change-driven docs: generate only what the latest diff justifies.
- Safe and predictable: conservative updates, no fabrication, English-only.
- CI-friendly: minimal dependencies, idempotent runs, anti-loop protections.

## Main Components
- `entrypoint.sh`: orchestrates diff collection, prompt assembly, Codex CLI invocation, and PR creation.
- `prompts/default.md`: template with strict, change-only instructions and SMART_TIMELINE.md rules.
- Outputs: generated pages under `docs/` and, optionally, an append-only `SMART_TIMELINE.md`.

## Main Flow
1) Detect changed files and unified diffs.
2) Build a prompt with the diffs and configuration.
3) Run Codex CLI (workspace-write sandbox) to generate docs.
4) Write docs under `docs/` and optionally append to `SMART_TIMELINE.md`.
5) On pushes, create a branch `smart-doc/docs-update-<short-sha>` and open a PR with auto-merge (squash) when allowed.

## Notable Decisions
- Replaced `HISTORY.md` with `SMART_TIMELINE.md` for the append-only documentation timeline, and updated references in workflows, prompts, and logs. Anti-loop `paths-ignore` now includes `SMART_TIMELINE.md`.

