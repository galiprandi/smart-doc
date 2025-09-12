#!/usr/bin/env bash
# /**
#  * Smart Doc — Prompt Builder
#  * Responsibility:
#  *   - Build the final prompt text from a template and a source of changes (diffs).
#  *   - Resolve changes from git (base/merge-base), include-working, or an injected unified diff file.
#  *   - Produce a deterministic, minimal prompt (Changed files, Changed patches, Metadata, Policies from template).
#  * Invariants (keep in future iterations):
#  *   - Never write repository files; output prompt to stdout only.
#  *   - Keep logs concise with emojis; avoid dumping large diffs to logs (diff goes only into the prompt).
#  *   - Accept the same env inputs used by the Action: INPUT_BRANCH, INPUT_PROMPT_TEMPLATE, INPUT_DOCS_FOLDER,
#  *     INPUT_PATCH_FILE, INPUT_INCLUDE_WORKING, INPUT_GENERATE_HISTORY.
#  *   - Default to prompts/default.md when no template is provided.
#  */
set -euo pipefail

log() { echo "📝 [prompt-builder] $*" >&2; }
warn() { echo "::warning::⚠️ $*" >&2; }
err() { echo "::error::❌ $*" >&2; }

# Inputs (via env)
INPUT_BRANCH=${INPUT_BRANCH:-main}
INPUT_PROMPT_TEMPLATE=${INPUT_PROMPT_TEMPLATE:-}
INPUT_DOCS_FOLDER=${INPUT_DOCS_FOLDER:-docs}
INPUT_PATCH_FILE=${INPUT_PATCH_FILE:-}
INPUT_INCLUDE_WORKING=${INPUT_INCLUDE_WORKING:-false}
INPUT_GENERATE_HISTORY=${INPUT_GENERATE_HISTORY:-true}

# Resolve template
TEMPLATE_FILE=""
if [[ -n "$INPUT_PROMPT_TEMPLATE" && -f "$INPUT_PROMPT_TEMPLATE" ]]; then
  TEMPLATE_FILE="$INPUT_PROMPT_TEMPLATE"
elif [[ -n "${GITHUB_ACTION_PATH:-}" && -f "${GITHUB_ACTION_PATH}/prompts/default.md" ]]; then
  TEMPLATE_FILE="${GITHUB_ACTION_PATH}/prompts/default.md"
elif [[ -f "prompts/default.md" ]]; then
  TEMPLATE_FILE="prompts/default.md"
else
  err "Prompt template not found. Set INPUT_PROMPT_TEMPLATE or include prompts/default.md"
  exit 1
fi

### Consume diff-detector outputs if present
TMP_DIR="tmp"
mkdir -p "$TMP_DIR"
CHANGED_FILES_FILE="$TMP_DIR/changed_files.txt"
PATCH_FILE="$TMP_DIR/patch.diff"

CHANGED_FILES=""
PATCH_CONTENT=""

if [[ -f "$CHANGED_FILES_FILE" ]]; then
  CHANGED_FILES=$(cat "$CHANGED_FILES_FILE")
else
  warn "changed_files.txt not found; proceeding without file list."
fi
if [[ -f "$PATCH_FILE" ]]; then
  PATCH_CONTENT=$(cat "$PATCH_FILE")
else
  warn "patch.diff not found; proceeding without unified diff."
fi

if [[ -z "${CHANGED_FILES//[[:space:]]/}" ]]; then
  log "No changed files provided. Emitting template with metadata only."
fi

# Build prompt to stdout
cat "$TEMPLATE_FILE"
echo
echo "---"
echo "Changed files:"
if [[ -n "${CHANGED_FILES//[[:space:]]/}" ]]; then
  echo "$CHANGED_FILES"
fi
echo "Docs folder: $INPUT_DOCS_FOLDER"
echo "Generate SMART_TIMELINE.md: $INPUT_GENERATE_HISTORY"
if [[ -n "$PATCH_CONTENT" ]]; then
  echo
  echo "Changed patches (unified diff):"
  echo '```diff'
  printf "%s\n" "$PATCH_CONTENT"
  echo '```'
fi
