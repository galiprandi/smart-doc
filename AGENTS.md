# AGENTS.md — Guidance for AI agents working in this repo

Purpose
- This repository contains “Smart Doc”, a composite GitHub Action that keeps project documentation up‑to‑date on every integration by turning commit diffs into docs under `docs/` (and optionally `SMART_TIMELINE.md`).
- Audience for this file: any AI agent (or human) contributing to this repo. It explains goals, guardrails, and how to interact with the codebase safely.

Scope and Intent
- Do not change user project code. Smart Doc only generates documentation pages.
- Documentation language: English. Content should be concise, change‑driven, and idempotent (no churn).
- Preferred behavior: update only what is relevant to the current commit’s diff and immediate context.

Repository Structure (key files)
- `action.yml`: Composite GitHub Action metadata and inputs.
- `entrypoint.sh`: Orchestrator. Delegates to scripts (validator → diff‑detector → prompt‑builder → doc‑updater → publisher). Invokes Codex CLI in workspace‑write.
- `scripts/validator.sh`: Early checks (API key, tools, template). Fails fast only on critical requirements.
- `scripts/diff-detector.sh`: Resolves changed files and unified diff (git, include‑working, or injected patch via `INPUT_PATCH_FILE`).
- `scripts/prompt-builder.sh`: Builds the final prompt from template + diff outputs (does not resolve diffs itself).
- `scripts/doc-updater.sh`: Runs Codex CLI (workspace‑write) with the built prompt and signals if docs changed.
- `scripts/publisher.sh`: Creates/updates PR on push events if there are changes; no‑op on pull_request events.
- `prompts/default.md`: Instruction template for generation (English, change‑only, no fabrication). Includes SMART_TIMELINE.md spacing rules.
- `.github/workflows/test.yml`: Example/house workflow to run Smart Doc with:
  - paths‑ignore for docs‑only commits
  - job‑level anti‑loop condition
  - permissions for `contents: write` and `pull-requests: write`
  - concurrency with `cancel-in-progress: true`
- `README.md`: Marketing‑oriented overview and copy‑paste workflows (kept in English). Reflects auto‑merge PR behavior, model compatibility (OpenAI/Qwen), and anti‑loop snippet.
- `docs/`: Output folder for generated documentation (architecture, modules, stack, etc.).
- `SMART_TIMELINE.md`: Append‑only documentation timeline (English). Each entry must be separated by exactly one blank line and follow the format defined in `prompts/default.md`.

Operation (high level)
- Entrypoint runs the pipeline:
  1) validator → 2) diff‑detector (writes tmp/changed_files.txt, tmp/patch.diff) → 3) prompt‑builder (produces tmp/prompt.md) → 4) doc‑updater (Codex write; sets tmp/have_changes.flag) → 5) publisher (only on push, if changes).
- On PR runs, publishing is skipped by design (no push, no PR).

Inputs and Secrets
- Required secret: `SMART_DOC_API_TOKEN` (exported as `OPENAI_API_KEY`).
- Configurable inputs (see `action.yml`): `branch`, `docs_folder`, `prompt_template`, `model`, `generate_history`. Advanced: `INPUT_INCLUDE_WORKING` and `INPUT_PATCH_FILE` (diff injection) for previews/tests.
- GitHub CLI (`gh`) and `GITHUB_TOKEN` are used for opening PRs. The diff detector prefers local git; `gh compare` is optional.

Agent Guardrails
- Do: keep README marketing‑focused, in English, and synchronized with real behavior (auto‑merge PR, permissions, anti‑loop, concurrency).
- Do: preserve `entrypoint.sh` safety patterns (set -euo pipefail; minimal, readable Bash).
- Do: ensure SMART_TIMELINE.md entries strictly follow the format in `prompts/default.md` with blank line separation.
- Do: maintain branch name prefix `smart-doc/docs-update-` for generated PRs.
- Don’t: push directly to protected branches. The Action must open a PR instead.
- Don’t: remove or rewrite existing docs without grounding in the current diff.
- Don’t: introduce model/provider‑specific code paths in `entrypoint.sh` beyond what’s already supported via CLI flags and `action.yml` inputs.

Editing Guidelines
- Keep changes minimal and focused. Align with current shell style (Bash, strict mode, small scripts, clear logs with emojis).
- Avoid introducing new dependencies unless necessary for CI portability (Ubuntu runner) or the future CLI migration.
- When updating prompts:
  - Keep them English‑only, explicit about “change‑only updates”, and “no fabrication”.
  - Include precise SMART_TIMELINE.md formatting rules (one blank line between entries; trailing newline; append‑only).

Workflow Defaults and Anti‑loop
- Use the “pro” snippet in README:
  - `paths-ignore` for `docs/**` and `SMART_TIMELINE.md` on push
  - Job‑level `if` to skip when actor is `github-actions[bot]` or ref starts with `smart-doc/docs-update-`
  - `concurrency` with `cancel-in-progress: true`

Consumption (for external users)
- Recommended reference: `uses: galiprandi/smart-doc@v1` (stable tag created and released).
- Example workflows in README include permissions and anti‑loop guards.

Prompt tuning tips (local)
- Use diff injection to iterate the prompt without changing repo state:
  - `bash scripts/run-smart-doc-local.sh --patch scripts/fixtures/test.patch`
  - Include working tree changes if needed: `--include-working`
- See `scripts/README.md` → “Diff injection (test mode)” for more examples.

Testing/Validation
- No unit tests. Validate by pushing a small change and confirming:
  - A branch `smart-doc/docs-update-<sha>` is created
  - A PR is opened with auto‑merge enabled when allowed
  - Docs are generated under `docs/` in English and scoped to the diff

Appendix: Fallbacks and markers
- The Action path does not rely on a Responses API fallback. If you are an external agent running in a read‑only environment, prefer returning a single patch (*** Begin Patch … *** End Patch) or explicit file markers to communicate changes; do not change this repository’s fallback behavior.

Thank you
- Keep Smart Doc simple, predictable, and marketing‑friendly. If in doubt, prefer conservative, change‑only doc updates and clear PRs over broad rewrites.
