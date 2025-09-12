# Module: prompts/default.md

## Purpose
Defines the instruction template used to convert commit diffs into concise documentation under `docs/` (and optionally `SMART_TIMELINE.md`).

## Behavior Updated in This Commit
- Replaced references to `HISTORY.md` with `SMART_TIMELINE.md`.
- Timeline entry format expanded to include: PR number, short commit SHA, optional ticket keys, and clearer Scope (areas/paths). Spacing rules: exactly one blank line between entries and a trailing newline at EOF.

## Responsibilities
- Enforce change-only updates and forbid fabrication.
- Constrain outputs to English and to `docs/` plus optional `SMART_TIMELINE.md`.
- Provide explicit formatting rules for the timeline file.

## TODO
- Add a brief example timeline entry inline in the template when appropriate to reduce formatting errors.

