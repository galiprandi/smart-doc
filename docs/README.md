# Smart Doc — Internal Docs

## Overview
Smart Doc generates concise, change-driven documentation from each commit’s diff. It writes only under `docs/` and can optionally append entries to `SMART_TIMELINE.md`. The Action is PR-first and respects protected branches.

## What’s new in this update
This commit refines internal scripts and adds small, documented hints:

- `scripts/diff-detector.sh`: ensures `tmp/changed_files.txt` and `tmp/patch.diff` are initialized and adds a TODO for a future `INPUT_MAX_FILES` threshold (non-blocking).
- `scripts/doc-updater.sh`: clarifies model selection via `INPUT_MODEL` (default `gpt-5-nano`) and notes a future `--dry-run` flag at the LLM level.

## Quickstart
- See the top-level [README](../README.md) for setup, inputs, and workflow examples.
- Canonical generation rules live in [prompts/default.md](../prompts/default.md).

## Change gating
To reduce churn and noise, Smart Doc applies strict change gating:
- Only update docs when the improvement is meaningful (clarifies behavior, fixes inaccuracies, or documents new/changed components).
- Skip micro-edits and cosmetic changes that don’t materially improve understanding.
- If nothing meets the bar, do not write files or open a PR.

## Documentation conventions
Follow the Semantic Markdown requirements defined in [prompts/default.md](../prompts/default.md) (English, one H1 per file, logical sections, fenced code blocks with language tags, single trailing newline).

## Current docs
- `docs/README.md` — this page.
- `SMART_TIMELINE.md` — append-only change list at the repo root.
- `docs/modules/diff-detector.md` — module notes for `scripts/diff-detector.sh`.
- `docs/modules/doc-updater.md` — module notes for `scripts/doc-updater.sh`.

TODO: Reintroduce broader architecture and stack docs when future diffs touch those areas.
