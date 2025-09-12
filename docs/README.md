# Smart Doc — Internal Docs

## Overview
Smart Doc generates concise, change-driven documentation from each commit’s diff. It writes only under `docs/` and can optionally append entries to `SMART_TIMELINE.md`. The Action is PR-first and respects protected branches.

## What’s new in this update
- Added a change gating policy in the prompt to avoid unnecessary PRs/commits (meaningful improvements only; skip micro-edits).
- Prompt template expanded to include project-type–aware scaffolding and an opportunistic improvement policy when touching existing pages.
- Smart Timeline format updated to keyed fields (`Title`, `Merge`, `Scope`, `TL;DR`) with strict spacing rules.
- This page was reintroduced after a prior removal to keep minimal, up-to-date docs.

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
- TODO: Reintroduce architecture and stack docs when future diffs touch those areas.
