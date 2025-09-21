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
- The main script runs the pipeline:
  1) validator → 2) diff‑detector (writes tmp/changed_files.txt, tmp/patch.diff) → 3) prompt‑builder (produces tmp/prompt.md) → 4) doc‑updater (Codex write; sets tmp/have_changes.flag) → 5) publisher (only on push, if changes).
- On PR runs, publishing is skipped by design (no push, no PR).

Inputs and Secrets
- Required secret: `OPENAI_API_KEY`.
- Configurable inputs (see `action.yml`): `model`.
- GitHub CLI (`gh`) and `GITHUB_TOKEN` are used for opening PRs. The diff detector prefers local git; `gh compare` is optional.

Qwen usage (provider switch)
- To run with Qwen Code via Ollama locally: set `provider: ollama` and `model: qwen2.5-coder` (or your local tag). No extra secret is needed.
- To run with a hosted Qwen on an OpenAI‑compatible endpoint (e.g., Together/Fireworks/OpenRouter): set `provider: openai`, provide `model` and `openai_base_url` to the provider’s base URL.

Jira MCP (optional, auto-configured)
- If the environment variables `JIRA_EMAIL`, `JIRA_API_TOKEN`, and `JIRA_DOMAIN` are present and non-empty, `scripts/validator.sh` will create (or overwrite) `~/.codex/config.toml` with a Jira MCP server configuration:
  - `[mcp_servers.jira]`, `command = "node"`, `args = ["/path/to/jira-server/build/index.js"]` and an `env` block containing the three variables.
- On success, the validator logs: `⚙️ Jira MCP configured at ~/.codex/config.toml`.
- If any variable is missing or empty, the validator performs no MCP action and prints nothing about MCP.
- This configuration is written to the user home (not the repository) and can be consumed by Codex or compatible MCP clients.

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

Local Docker (Ubuntu) for development
- A Dockerfile is provided to run Smart Doc’s doc generation in an Ubuntu environment where the CLI is stable.
- Build:
  - `docker build -t smart-doc-dev .`
- Run (mounts repo and uses your API key):
  - `docker run --rm -e OPENAI_API_KEY=$OPENAI_API_KEY -v "$PWD":/app smart-doc-dev bash scripts/dev-run-docs.sh --prompt prompts/default.md --docs-out docs-out --clean`
- Outputs appear under `docs-out/` in your repo on the host.

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

Local development helper
- A helper script exists to exercise only the documentation generation step with arbitrary prompts, writing into an isolated folder and showing its tree at the end.
- Script: `scripts/dev-run-docs.sh`
- Usage:
  - `bash scripts/dev-run-docs.sh --prompt <file.md> [--model <id>] [--docs-out <dir>] [--clean]`
  - `bash scripts/dev-run-docs.sh --prompts-dir <dir> [--model <id>] [--docs-out <dir>] [--clean]`
  - Defaults:
    - `--model`: `gpt-5-nano`
    - `--docs-out`: `docs-out` (timeline is colocated as `docs-out/SMART_TIMELINE.md`)
    - `--clean`: when provided, removes the output folder before running
  - Behavior:
    - Runs only `scripts/doc-updater.sh` with the provided prompt; does not publish PRs or touch branches.
    - Writes generated docs under `<docs-out>/docs/` and timeline at `<docs-out>/SMART_TIMELINE.md`.
    - Prints a directory tree (or `find` fallback) of `<docs-out>` on completion.
  - Examples:
    - `bash scripts/dev-run-docs.sh --prompt prompts/default.md --clean`
    - `bash scripts/dev-run-docs.sh --prompt prompts/default.md --docs-out my-eval --model gpt-4o-mini --clean`
    - `bash scripts/dev-run-docs.sh --prompts-dir prompts --docs-out evals --clean`
  - Requirements:
    - Codex CLI available (`code`, `codex`, or `npx @openai/codex`).
    - API key in `OPENAI_API_KEY` for real generations; otherwise the script logs a warning and no docs will be changed.

Robustness note
- `scripts/doc-updater.sh` was hardened to avoid reliance on `mapfile` and to initialize CLI return handling, improving portability in local shells/macOS sandboxes.

Appendix: GitHub MCP tools (available in Codex CLI)
- The following GitHub tools are typically available to agents running via Codex CLI in this repository’s workflows. Availability can depend on credentials and runtime context.

- Pull Requests: `list_pull_requests`, `get_pull_request`, `get_pull_request_status`, `get_pull_request_diff`, `get_pull_request_files`, `get_pull_request_reviews`, `get_pull_request_review_comments`, `create_pull_request`, `update_pull_request`, `merge_pull_request`, `update_pull_request_branch`, `create_pending_pull_request_review`, `add_comment_to_pending_review`, `submit_pending_pull_request_review`, `delete_pending_pull_request_review`, `request_copilot_review`, `assign_copilot_to_issue`.
- Issues: `create_issue`, `get_issue`, `list_issues`, `update_issue`, `add_issue_comment`, sub-issues (`add_sub_issue`, `list_sub_issues`, `remove_sub_issue`, `reprioritize_sub_issue`), `list_issue_types`.
- Repos/Branches/Files: `create_repository`, `fork_repository`, `list_branches`, `create_branch`, `get_file_contents`, `create_or_update_file`, `delete_file`, `push_files`, tags/releases (`list_tags`, `get_tag`, `list_releases`, `get_latest_release`, `get_release_by_tag`), stars (`star_repository`, `unstar_repository`, `list_starred_repositories`).
- Commits: `list_commits`, `get_commit`.
- Actions (Workflows): `list_workflows`, `list_workflow_runs`, `get_workflow_run`, `get_workflow_run_usage`, `list_workflow_jobs`, `get_job_logs`, `get_workflow_run_logs`, `list_workflow_run_artifacts`, `download_workflow_run_artifact`, `run_workflow`, `rerun_workflow_run`, `rerun_failed_jobs`, `cancel_workflow_run`, `delete_workflow_run_logs`.
- Notifications: `list_notifications`, `get_notification_details`, `dismiss_notification`, `manage_notification_subscription`, `manage_repository_notification_subscription`, `mark_all_notifications_read`.
- Security: code scanning (`list_code_scanning_alerts`, `get_code_scanning_alert`), Dependabot (`list_dependabot_alerts`, `get_dependabot_alert`), secret scanning (`list_secret_scanning_alerts`, `get_secret_scanning_alert`), advisories (`list_repository_security_advisories`, `list_org_repository_security_advisories`, `list_global_security_advisories`, `get_global_security_advisory`).
- Discussions: `list_discussions`, `list_discussion_categories`, `get_discussion`, `get_discussion_comments`.
- Gists: `create_gist`, `update_gist`, `list_gists`.
- Teams: `get_teams`, `get_team_members`.
- Search: `search_repositories`, `search_pull_requests`, `search_issues`, `search_code`, `search_users`, `search_orgs`.
- Profile: `get_me`.

Appendix: Fallbacks and markers
- The Action path does not rely on a Responses API fallback. If you are an external agent running in a read‑only environment, prefer returning a single patch (*** Begin Patch … *** End Patch) or explicit file markers to communicate changes; do not change this repository’s fallback behavior.

Thank you
- Keep Smart Doc simple, predictable, and marketing‑friendly. If in doubt, prefer conservative, change‑only doc updates and clear PRs over broad rewrites.

Field Notes — Minimal Flow (2025-09-20)

Context
- To unblock CI while prompts/CLI were unreliable, we introduced a minimal inline entrypoint that guarantees a safe, observable change per run without external scripts.

What changed
- `.github/workflows/smart-doc.yml`: simplified step to pass only the API key and export `OPENAI_API_KEY`.
- `entrypoint.sh`: now can operate in a minimal mode that:
  - Appends exactly one compliant line to `SMART_TIMELINE.md` (spacing: one blank line between entries; trailing newline).
  - Commits, pushes a `smart-doc/docs-update-<epoch>` branch, and opens a PR via `gh`.
- This bypasses validator/diff-detector/prompt-builder/doc-updater/publisher for diagnosis; use as fallback, not as default forever.

Why it worked
- Removed dependencies on model/prompt/CLI availability, validating permissions and PR flow end‑to‑end.

Evolution Plan (incremental)
- Phase 1: Externalize a minimal prompt file (English) and allow switching between Mini (timeline-only) and Standard (model-driven) via an input/env flag. Keep timeline append in both modes for observability.
- Phase 2: Re‑enable the full pipeline behind a circuit breaker: if model path fails or yields no changes, fall back to timeline-only append to avoid “no-op” runs.
- Phase 3: Tune `prompts/default.md` for high-signal, change-only updates (README/stack/architecture/modules touched by the diff) plus an always-on, compliant SMART_TIMELINE.md entry.
- Phase 4: Add PR review comment on pull_request runs summarizing doc changes and linking to the artifact/timeline diff.
- Phase 5: resilience (retries/backoff, clearer logs), and maintain README examples (permissions, anti-loop, concurrency) in sync.

Guardrails retained
- PR branch prefix `smart-doc/docs-update-`.
- No direct pushes to protected branches; PRs only.
- Timeline spacing rules remain strict.
