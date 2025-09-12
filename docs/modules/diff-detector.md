# Diff Detector

## Purpose
Resolves the list of changed files and the unified diff for the current run. Outputs artifacts used by prompt building and documentation generation.

## Key Files
- `scripts/diff-detector.sh`

## Behavior (as of this commit)
- Initializes temporary outputs early:
  - `tmp/changed_files.txt`
  - `tmp/patch.diff`
- Reads inputs:
  - `INPUT_BRANCH` (default: `main`)
  - `INPUT_INCLUDE_WORKING` (default: `false`)
  - `INPUT_PATCH_FILE` (default: empty; allows injected diffs for previews/tests)
- Logs via simple helpers and runs with strict Bash flags (`set -euo pipefail`).

## Notable Changes
- Adds a TODO note to support a non-blocking `INPUT_MAX_FILES` threshold in the future.

## Outputs
- `tmp/changed_files.txt`: newline-separated list of paths considered changed.
- `tmp/patch.diff`: unified diff across the resolved changes.

## TODO
- Implement optional `INPUT_MAX_FILES` threshold and associated warnings/exit semantics.

