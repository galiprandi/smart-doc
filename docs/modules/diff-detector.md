# Module: diff-detector

- Purpose: detect changes from a commit and emit a patch for downstream steps.
- Key outputs: `tmp/changed_files.txt`, `tmp/patch.diff`.
- Interfaces: reads `INPUT_BRANCH`, `INPUT_INCLUDE_WORKING`, `INPUT_PATCH_FILE`.
- Risks/Notes: ensure non-destructive writes; idempotent in repeated runs.

