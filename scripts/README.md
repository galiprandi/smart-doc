# Smart Doc — Local Runner

This folder contains a helper script to run the Smart Doc Action locally in a safe preview mode (no commits, no PRs).

## Files
- `run-smart-doc-local.sh`: executes the Action's `entrypoint.sh` simulating a `pull_request` event.
- `../.env.example`: template for secrets and optional settings. Copy it to `.env` at the repo root.

## Requirements
- `git`, `jq`, `curl` installed.
- An `.env` file at the repo root with `SMART_DOC_API_TOKEN`.

## Setup
1. Copy `.env.example` to `.env` and set your API key:
   ```bash
   cp .env.example .env
   # edit .env and set SMART_DOC_API_TOKEN=sk-xxxx
   ```
2. Make the script executable (once):
   ```bash
   chmod +x scripts/run-smart-doc-local.sh
   ```

## Run
Minimal run (uses `prompts/default.md`, base `main`, writes previews under `docs/`):
```bash
bash scripts/run-smart-doc-local.sh
```

Custom base branch, custom prompt, and disable timeline generation:
```bash
bash scripts/run-smart-doc-local.sh \
  --base develop \
  --prompt prompts/default.md \
  --history false
```

## Diff injection (test mode)
Inject a unified diff to iterate the prompt without touching the repo state.

- Using the local runner directly:
  ```bash
  bash scripts/run-smart-doc-local.sh --patch scripts/fixtures/test.patch
  ```
- Include uncommitted changes in addition to the patch:
  ```bash
  bash scripts/run-smart-doc-local.sh --patch scripts/fixtures/test.patch --include-working
  ```

You can also generate a patch from your working tree:
```bash
git diff -U3 main...HEAD > /tmp/test.patch
bash scripts/run-smart-doc-local.sh --patch /tmp/test.patch
```

## Test runner helper
`test-smart-doc.sh` is a thin wrapper around the local runner with sensible defaults.

Examples:
```bash
# Use the bundled repo-related fixture
bash scripts/test-smart-doc.sh --patch scripts/fixtures/test.patch

# Include working tree changes and choose a different base
bash scripts/test-smart-doc.sh --patch /tmp/test.patch --include-working --base develop
```

What to expect:
- The script simulates a PR event, so `entrypoint.sh` will not push or open PRs.
- Generated content is written under `docs/` (and `SMART_TIMELINE.md` only if produced), allowing you to iterate on the prompt safely.
- A short preview of changed files is printed at the end.

## Tips
- Use a dedicated test branch while editing `prompts/default.md`.
- Commit only your prompt changes; generated docs from local runs are previews.
- If you need the full CI experience without pushes, also consider a PR-only workflow with an artifact upload step.
