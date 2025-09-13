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
# Hint model selection for clients that read OPENAI_MODEL
export OPENAI_MODEL="$MODEL"
log "Running using model $MODEL"
set +e
CODEX_LOG="$TMP_DIR/codex.log"
: > "$CODEX_LOG"
if command -v code >/dev/null 2>&1; then
  code exec --sandbox "$CODEX_SANDBOX" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1
  rc=$?
elif command -v codex >/dev/null 2>&1; then
  codex exec --sandbox "$CODEX_SANDBOX" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1
  rc=$?
else
  npx -y @openai/codex exec --sandbox "$CODEX_SANDBOX" "$(cat "$PROMPT_FILE")" >"$CODEX_LOG" 2>&1
  rc=$?
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
  echo "no" > "$CHANGES_FLAG"
fi

exit 0
