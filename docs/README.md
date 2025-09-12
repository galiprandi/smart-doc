# Smart Doc — Internal Docs

## Overview
Smart Doc generates concise, change-driven documentation from each commit’s diff. It writes only under `docs/` and can optionally append entries to `SMART_TIMELINE.md`.

## What’s new in this update
- Semantic Markdown requirements were codified in `prompts/default.md`; this page follows those rules.
- Legacy pages under `docs/architecture/` and `docs/modules/` were removed in this commit and will be rebuilt incrementally based on future diffs.

## Quickstart
- See the top-level `README.md` for setup and workflow examples.

## Documentation conventions
The generator now enforces semantic Markdown:
- One clear heading hierarchy (`#` to `####`) with exactly one H1 per file.
- Short, focused sections ordered logically (e.g., Overview → How it works → Configuration).
- Unordered lists for short items; ordered lists for steps; avoid overly deep nesting.
- Descriptive links using relative paths (e.g., `../README.md`), not “click here”.
- Fenced code blocks with language tags (```bash, ```yaml, ```json, ```mermaid); inline code for identifiers.
- Tables only when they improve scanability; include a header row.
- Prefer Mermaid for diagrams; include meaningful alt text if images are used.
- Concise, active voice; no raw HTML unless strictly needed.
- Formatting hygiene: reasonable line width (≤120 chars), no trailing spaces, single trailing newline.

For the full, canonical guidance, see the “Semantic Markdown requirements” section in the prompt template: `../prompts/default.md`.

## Current docs
- `docs/README.md` — this page.
- TODO: Reintroduce architecture and stack docs when future diffs touch those areas.

