Module: action.yml

Purpose
- Defines composite action inputs and environment for `entrypoint.sh`.

Key inputs (delta)
- `merge_mode` (default `auto`): Controls merge behavior — `auto`, `immediate`, or `off`.
- `merge_wait_seconds` (default `10`): Seconds to wait between mergeability checks.
- `merge_max_attempts` (default `30`): Maximum polling attempts for mergeability.
- `ready_pr_if_draft` (default `true`): Convert draft PRs to ready for review before merging.

Existing inputs (context)
- `branch` (default `main`), `docs_folder`, `prompt_template`, `model`, `generate_history`.
- `smart_doc_api_token` (required), optional `jira_*`, `clickup_token`.

Behavioral notes
- Inputs are exported as `INPUT_*` env vars and consumed by `entrypoint.sh`.
- Merge orchestration is performed by the script using `gh pr ready` and `gh pr merge` per the selected mode.

TODO
- Document any future merge strategies or provider‑specific flags if introduced.

