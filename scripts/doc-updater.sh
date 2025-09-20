#!/usr/bin/env bash
# /**
#  * Smart Doc — Doc Updater
#  * Responsibility:
#  *   - Execute the LLM (Codex CLI) in workspace-write mode using a built prompt.
#  *   - Detect whether any files under docs/ or SMART_TIMELINE.md changed.
#  *   - Persist a change signal for downstream publisher.
#  * Invariants (keep in future iterations):
#  *   - Never commit or push; only write in working tree via Codex and report changes.
#  *   - Read prompt from tmp/prompt.md unless PROMPT_FILE is explicitly provided.
#  *   - Keep logs concise with emojis.
#  */
set -euo pipefail

log() { echo "✍️  [doc-updater] $*"; }
warn() { echo "::warning::⚠️ $*"; }
err() { echo "::error::❌ $*"; }

INPUT_DOCS_FOLDER=${INPUT_DOCS_FOLDER:-docs}
PROMPT_FILE=${PROMPT_FILE:-tmp/prompt.md}
MODEL=${INPUT_MODEL:-gpt-5-nano}

# Prepare tmp dir and flag
# Hint model selection for clients that read env vars
export OPENAI_MODEL="$MODEL"
export CODEX_MODEL="$MODEL"
TMP_DIR="tmp"
mkdir -p "$TMP_DIR"
CHANGES_FLAG="$TMP_DIR/have_changes.flag"
: > "$CHANGES_FLAG"

if [[ ! -f "$PROMPT_FILE" ]]; then
  warn "Prompt file not found: $PROMPT_FILE. Nothing to do."
  echo "no" > "$CHANGES_FLAG"
  exit 0
fi

# Snapshot before
before=$(git status --porcelain -- "$INPUT_DOCS_FOLDER" SMART_TIMELINE.md 2>/dev/null || true)

# Run Codex CLI in workspace-write mode
export CODEX_SANDBOX="workspace-write"
export CODEX_REASONING_EFFORT="medium"
log "Running using model $MODEL"

# Build optional --model flag if supported by the installed CLI
build_model_args() {
  local cmd="$1"
  if "$cmd" exec --help 2>/dev/null | grep -q -- "--model"; then
    printf -- "--model\n%s\n" "$MODEL"
  fi
}

set +e
CODEX_LOG="$TMP_DIR/codex.log"
: > "$CODEX_LOG"
rc=0
if command -v code >/dev/null 2>&1; then
  MODEL_ARGS_STR="$(build_model_args code || true)"
  if [[ -n "$MODEL_ARGS_STR" ]]; then
    code exec --sandbox "$CODEX_SANDBOX" --model "$MODEL" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1 || rc=$?
  else
    code exec --sandbox "$CODEX_SANDBOX" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1 || rc=$?
  fi
elif command -v codex >/dev/null 2>&1; then
  MODEL_ARGS_STR="$(build_model_args codex || true)"
  if [[ -n "$MODEL_ARGS_STR" ]]; then
    codex exec --sandbox "$CODEX_SANDBOX" --model "$MODEL" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1 || rc=$?
  else
    codex exec --sandbox "$CODEX_SANDBOX" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1 || rc=$?
  fi
else
  if npx -y @openai/codex exec --help 2>/dev/null | grep -q -- "--model"; then
    npx -y @openai/codex exec --sandbox "$CODEX_SANDBOX" --model "$MODEL" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1 || rc=$?
  else
    npx -y @openai/codex exec --sandbox "$CODEX_SANDBOX" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1 || rc=$?
  fi
fi
set -e
if [[ $rc -ne 0 ]]; then
  warn "Codex CLI execution failed or returned non-zero ($rc). See $CODEX_LOG for details."
  if grep -q "401 Unauthorized" "$CODEX_LOG" 2>/dev/null; then
    warn "Codex reported 401 Unauthorized. Verify INPUT_SMART_DOC_API_TOKEN/OPENAI_API_KEY has access to the selected model."
  fi
fi

# Snapshot after
after=$(git status --porcelain -- "$INPUT_DOCS_FOLDER" SMART_TIMELINE.md 2>/dev/null || true)

if [[ -n "$after" && "$after" != "$before" ]]; then
  log "Detected documentation changes."
  echo "yes" > "$CHANGES_FLAG"
else
  log "No documentation changes detected."
  # Cold-start baseline: if docs is empty and full_repo_when_missing_docs is enabled, create a minimal README
  # This ensures first-run scaffolding so the publisher can persist something on cold start.
  DOCS_EMPTY=true
  if [[ -d "$INPUT_DOCS_FOLDER" ]]; then
    # Count non-hidden files
    count=$(find "$INPUT_DOCS_FOLDER" -type f -not -name ".*" | wc -l | tr -d '[:space:]')
    [[ "$count" != "0" ]] && DOCS_EMPTY=false || true
  fi
  if [[ "${INPUT_FULL_REPO_WHEN_MISSING_DOCS:-}" == "true" && "$DOCS_EMPTY" == true ]]; then
    log "Cold start detected (empty $INPUT_DOCS_FOLDER) with full_repo_when_missing_docs=true. Creating initial documentation set."
    mkdir -p "$INPUT_DOCS_FOLDER/architecture" "$INPUT_DOCS_FOLDER/modules"
    # README.md
    cat > "$INPUT_DOCS_FOLDER/README.md" << 'EOF'
# Project Documentation

## Overview
This repository uses Smart Doc to generate documentation from code changes. This initial version is a cold‑start scaffold; subsequent runs will refine and expand it.

## Quickstart
- Install dependencies and run dev as described in the repository README.
- Documentation lives under `docs/` and is kept up to date by Smart Doc.

## Contents
- Stack: key packages, commands, environments.
- Architecture: high‑level overview and diagram.
- Endpoints: public HTTP endpoints and health checks.
EOF
    # stack.md
    cat > "$INPUT_DOCS_FOLDER/stack.md" << 'EOF'
# Stack

## Key Packages
- List core frameworks and libraries here (filled by next Smart Doc runs).

## Commands
- Document `package.json` scripts and common tasks.

## Environments
- Describe environment variables and profiles.
EOF
    # architecture/overview.md
    cat > "$INPUT_DOCS_FOLDER/architecture/overview.md" << 'EOF'
# Architecture Overview

## Goals
- Summarize system goals and constraints.

## Components
- List services/modules and responsibilities.

## Main Flow
- Describe key request/event flows.
EOF
    # architecture/diagram.md
    cat > "$INPUT_DOCS_FOLDER/architecture/diagram.md" << 'EOF'
# Architecture Diagram

```mermaid
flowchart LR
  Client --> API
  API --> Queue
  API --> DB
```
EOF
    # endpoints.md
    cat > "$INPUT_DOCS_FOLDER/endpoints.md" << 'EOF'
# Endpoints

- GET /health — Service liveness check.
- Add other public endpoints here.
EOF
    echo "yes" > "$CHANGES_FLAG"
  else
    echo "no" > "$CHANGES_FLAG"
  fi
fi

exit 0
