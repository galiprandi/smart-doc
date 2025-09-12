# Module: entrypoint.sh

## Purpose
Coordinates Smart Doc execution: gathers diffs, builds the generation prompt, invokes Codex CLI, writes outputs, and opens an auto-merge PR on push events.

## Responsibilities
- Collect changed files and unified diffs for the current event.
- Assemble a concise prompt (change-only, English-only, no fabrication).
- Call Codex CLI with `--sandbox workspace-write` and capture output markers.
- Write generated files under `docs/` and handle optional `SMART_TIMELINE.md` at the repo root.
- On push events, create `smart-doc/docs-update-<short-sha>` and open a PR with auto-merge when allowed.

## Behavior Updated in This Commit
- Renamed timeline handling from `HISTORY.md` to `SMART_TIMELINE.md`:
  - Logging and prompt summary now reference `SMART_TIMELINE.md`.
  - Output mapping treats `SMART_TIMELINE.md` as a root-level file alongside `docs/*`.
  - Continues to avoid auto-creating the file; relies on tool output when present.

## Inputs (selected)
- `generate_history` (action input): controls whether the generator should produce `SMART_TIMELINE.md` entries; default `true`.

## Dependencies
- `git`, `gh` (GitHub CLI), Bash (strict mode), Codex CLI (model configurable via inputs).

## TODO
- Clarify observable behavior when `generate_history` is set to `false` (document gating across PR vs push runs).

