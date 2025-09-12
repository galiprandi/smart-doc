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
- `entrypoint.sh`: Core logic. Builds prompts, gathers diffs, invokes Codex CLI, and creates an auto‑merge PR with generated docs.
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
- Smart Doc computes changed files + unified diffs, assembles a prompt, runs Codex CLI with `--sandbox workspace-write`, writes docs into `docs/`, then:
  - Creates branch `smart-doc/docs-update-<short-sha>`
  - Opens a PR to the target branch (default `main`) and enables auto‑merge (squash) when allowed
- On PR runs, it does not push changes; it can upload artifacts or comment a summary.

Inputs and Secrets
- Required secret: `SMART_DOC_API_TOKEN` (exported as `OPENAI_API_KEY`).
- Configurable inputs (see `action.yml`): `branch`, `docs_folder`, `prompt_template`, `model`, `generate_history`.
- GitHub CLI (`gh`) and `GITHUB_TOKEN` are used for comparing commits and opening PRs.

Agent Guardrails
- Do: keep README marketing‑focused, in English, and synchronized with real behavior (auto‑merge PR, permissions, anti‑loop, concurrency).
- Do: preserve `entrypoint.sh` safety patterns (set -euo pipefail; minimal, readable Bash).
- Do: ensure SMART_TIMELINE.md entries strictly follow the format in `prompts/default.md` with blank line separation.
- Do: maintain branch name prefix `smart-doc/docs-update-` for generated PRs.
- Don’t: push directly to protected branches. The Action must open a PR instead.
- Don’t: remove or rewrite existing docs without grounding in the current diff.
- Don’t: introduce model/provider‑specific code paths in `entrypoint.sh` beyond what’s already supported via CLI flags and `action.yml` inputs.

Editing Guidelines
- Keep changes minimal and focused. Align with current shell style (Bash, strict mode, small functions, clear logs).
- Avoid introducing new dependencies unless necessary for CI portability (Ubuntu runner).
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

Testing/Validation
- No unit tests. Validate by pushing a small change and confirming:
  - A branch `smart-doc/docs-update-<sha>` is created
  - A PR is opened with auto‑merge enabled when allowed
  - Docs are generated under `docs/` in English and scoped to the diff

Appendix: Fallbacks and markers
- The Action path does not rely on a Responses API fallback. If you are an external agent running in a read‑only environment, prefer returning a single patch (*** Begin Patch … *** End Patch) or explicit file markers to communicate changes; do not change this repository’s fallback behavior.

Thank you
- Keep Smart Doc simple, predictable, and marketing‑friendly. If in doubt, prefer conservative, change‑only doc updates and clear PRs over broad rewrites.
