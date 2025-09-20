# Smart Doc Documentation

Purpose: Provide concise, change-oriented documentation for Smart Doc as it evolves.

What’s here: explanation of how the diff-detector and doc-updater pieces affect documentation generation, plus quick pointers for contributors.

Quickstart (high level):
- The Diff Detector identifies changed files and produces a patch.
- The Doc Updater consumes a prompt built from the diff and generates docs under `docs/`.
- Changes are published via PRs following anti-loop rules.

Folder structure (high level):
- `docs/` – generated and authored docs for the project.
- `docs/architecture/` – architecture overview materials.
- `docs/modules/` – per-module documentation files touched by changes.
- `SMART_TIMELINE.md` – repository-wide change timeline.

Common commands (local):
- Run a local doc-generation flow: see `scripts/dev-run-docs.sh`.
- Inspect docs folder: `ls -la docs/`.

Internal links:
- See `docs/README.md` for overview and quicklinks.

