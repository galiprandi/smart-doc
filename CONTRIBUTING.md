# Contributing to Smart Doc

This guide is for contributors who work on Smart Doc itself. If you want to use the Action in your repository, see the user‑focused [`README.md`](./README.md) and [`USAGE.md`](./USAGE.md).

## Architecture (single responsibility scripts)
Smart Doc is a composite GitHub Action. The orchestration lives in `entrypoint.sh`, which delegates to five scripts with single responsibilities:

- validator — `scripts/validator.sh`
  - Checks environment/secrets and basic tooling. Fails fast only on critical requirements (API key).
- diff‑detector — `scripts/diff-detector.sh`
  - Resolves changed files and a unified diff (git, include‑working, or injected patch via `INPUT_PATCH_FILE`).
- prompt‑builder — `scripts/prompt-builder.sh`
  - Builds the final prompt from the template and diff outputs (does not resolve diffs itself).
- doc‑updater — `scripts/doc-updater.sh`
  - Runs the model (Codex CLI) in `workspace-write` mode using the built prompt; signals if docs changed.
- publisher — `scripts/publisher.sh`
  - On push to the base branch, creates/updates a PR for the documentation changes. No‑op on pull_request events.

Conventions:
- Strict Bash mode (`set -euo pipefail`).
- Minimal logs with emojis: Validator 🧪, Diff 🔎, Prompt 🧩, Update ✍️, Publish 🚀.
- Runtime artifacts live under `tmp/` and are ignored by Git.

## Local preview and test flows
You can iterate on the prompt and generation locally without committing anything.

- Basic local preview (simulates a PR run — no commits/pushes):
  ```bash
  bash scripts/run-smart-doc-local.sh
  ```
- Include unstaged working‑tree changes:
  ```bash
  bash scripts/run-smart-doc-local.sh --include-working
  ```
- Inject a unified diff (test mode) to iterate deterministically:
  ```bash
  bash scripts/run-smart-doc-local.sh --patch scripts/fixtures/test.patch
  # or use the helper
  bash scripts/test-smart-doc.sh --patch scripts/fixtures/test.patch
  ```
- Review results:
  ```bash
  sed -n '1,120p' tmp/prompt.md
  git status --porcelain docs SMART_TIMELINE.md
  ```

Requirements for local preview:
- `.env` at the repo root with `SMART_DOC_API_TOKEN` (exported to `OPENAI_API_KEY`). See `.env.example`.
- Tools: `git`, `jq`, `curl`. The CI installs `@openai/codex` if needed.

## CI workflows and branch policy
- Main workflow: `.github/workflows/smart-doc.yml`
  - PRs → preview only (no publishing). Optional artifact upload step can expose generated docs.
  - Push to `main` → publish path: `publisher.sh` creates/updates a docs PR on `smart-doc/docs-update-<sha>`.
- Guard for develop: `.github/workflows/guard-docs-develop.yml`
  - Blocks changes to `docs/**` and `SMART_TIMELINE.md` on `develop`. This keeps develop noise‑free; publish happens via `main`.

## Invariants to keep
- Entrypoint is a thin orchestrator. Do not re‑introduce diff or PR logic there.
- Prompt building never resolves diffs; it only consumes `tmp/changed_files.txt` and `tmp/patch.diff`.
- `doc-updater.sh` remains in Codex write mode without extra guard rails (security/constrains can be added later as a feature flag).
- Logs remain concise; do not print full diffs to logs (diffs go into the prompt).

## Coding style and commit conventions
- Bash: small functions, strict mode, clear logs, avoid subshells where not needed.
- Commit messages: `type(scope): subject` where meaningful. Examples: `fix(diff-detector): …`, `docs: …`, `ci: …`, `chore: …`.
- Keep PRs small and focused. Prefer mechanical refactors in separate commits.

## Troubleshooting
- "No changed files detected" on `main` push
  - The base merge‑base may equal `HEAD`. We fallback to `HEAD~1` to diff against the previous commit. If still zero, the change is likely outside the doc scope.
- PR not created
  - Ensure the model actually wrote files under `docs/` or `SMART_TIMELINE.md` and that job permissions include `contents: write` and `pull-requests: write`.
- Local preview writes to repo
  - This is expected for preview. Do not commit those files; they are previews. Use `git restore` if needed.

## Related docs
- User guide: [`README.md`](./README.md)
- Usage and recipes: [`USAGE.md`](./USAGE.md)
- Agent/automation guardrails: [`AGENTS.md`](./AGENTS.md)
- Prompt template: [`prompts/default.md`](./prompts/default.md)
