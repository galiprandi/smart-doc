#!/usr/bin/env bash
# /**
#  * Smart Doc — Entrypoint Orchestrator
#  * Responsibility:
#  *   - Orchestrate the Smart Doc pipeline in CI/local runs.
#  *   - Delegate to scripts: validator → diff-detector → prompt-builder → doc-updater → publisher.
#  * Invariants (keep in future iterations):
#  *   - No diff resolution or prompt assembly inline; always use scripts.
#  *   - Keep logs concise with emojis.
#  */
set -euo pipefail

log() { echo "📝 [smart-doc] $*"; }
warn() { echo "::warning::⚠️ $*"; }
err() { echo "::error::❌ $*"; }

INPUT_DOCS_FOLDER=${INPUT_DOCS_FOLDER:-docs}

## Git identity for commits (publisher handles PR push)
git config --global user.name "GitHub Action" || true
git config --global user.email "action@github.com" || true

# Ensure docs folder exists
mkdir -p "$INPUT_DOCS_FOLDER"

## 1) Validate environment and inputs
bash "${GITHUB_ACTION_PATH:-.}/scripts/validator.sh"

## 2) Detect diffs (writes tmp/changed_files.txt and tmp/patch.diff)
bash "${GITHUB_ACTION_PATH:-.}/scripts/diff-detector.sh"

## Early exit if no changed files
if [[ ! -s tmp/changed_files.txt ]]; then
  warn "No changed files detected. Nothing to document."
  exit 0
fi

## 3) Build prompt → tmp/prompt.md
PROMPT_FILE=$(mktemp)
BUILDER_PATH="${GITHUB_ACTION_PATH:-.}/scripts/prompt-builder.sh"
[[ -f "$BUILDER_PATH" ]] || BUILDER_PATH="./scripts/prompt-builder.sh"
bash "$BUILDER_PATH" > "$PROMPT_FILE"

## 4) Update docs via Codex write mode (sets tmp/have_changes.flag)
PROMPT_FILE="$PROMPT_FILE" bash "${GITHUB_ACTION_PATH:-.}/scripts/doc-updater.sh"

## 5) Publish PR if changes and event is push
bash "${GITHUB_ACTION_PATH:-.}/scripts/publisher.sh"

## 6) Post PR comment (on pull_request events)
if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  bash "${GITHUB_ACTION_PATH:-.}/scripts/post-pr-comment.sh"
fi

log "Smart Doc completed (publish handled by publisher.sh)."
