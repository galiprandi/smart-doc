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
INPUT_PROMPT_PRESET=${INPUT_PROMPT_PRESET:-default}
INPUT_GATING_PROFILE=${INPUT_GATING_PROFILE:-strict}
INPUT_FORCE_FULL_REPO=${INPUT_FORCE_FULL_REPO:-false}
INPUT_FULL_REPO_WHEN_MISSING_DOCS=${INPUT_FULL_REPO_WHEN_MISSING_DOCS:-true}

TMP_DIR="tmp"
mkdir -p "$TMP_DIR"
CHANGED_FILES_FILE="$TMP_DIR/changed_files.txt"
PATCH_FILE_DEFAULT="$TMP_DIR/patch.diff"

# Determine docs folder status
docs_missing=0
if [[ ! -d "$INPUT_DOCS_FOLDER" ]]; then
  docs_missing=1
else
  if [[ -z $(find "$INPUT_DOCS_FOLDER" -type f -not -name '.*' -maxdepth 2 2>/dev/null) ]]; then
    docs_missing=1
  fi
fi

# Full-repo mode?
full_repo_mode=false
shopt -s nocasematch
if [[ "$INPUT_FORCE_FULL_REPO" == "true" ]]; then
  full_repo_mode=true
elif [[ "$INPUT_FULL_REPO_WHEN_MISSING_DOCS" == "true" && $docs_missing -eq 1 ]]; then
  full_repo_mode=true
fi
shopt -u nocasematch

# Resolve template: custom wins; else compose preset + gating
output_template() {
  local preset_file gating_file
  preset_file="${GITHUB_ACTION_PATH:-.}/prompts/presets/${INPUT_PROMPT_PRESET}.md"
  gating_file="${GITHUB_ACTION_PATH:-.}/prompts/gating/${INPUT_GATING_PROFILE}.md"
  if [[ ! -f "$preset_file" ]]; then
    warn "Preset not found: $preset_file; falling back to prompts/presets/default.md"
    preset_file="${GITHUB_ACTION_PATH:-.}/prompts/presets/default.md"
  fi
  if [[ ! -f "$gating_file" ]]; then
    warn "Gating not found: $gating_file; falling back to prompts/gating/strict.md"
    gating_file="${GITHUB_ACTION_PATH:-.}/prompts/gating/strict.md"
  fi
  cat "$preset_file"
  echo
  cat "$gating_file"
}

if [[ -n "$INPUT_PROMPT_TEMPLATE" && -f "$INPUT_PROMPT_TEMPLATE" ]]; then
  cat "$INPUT_PROMPT_TEMPLATE"
else
  output_template
fi

# Collect diff inputs
CHANGED_FILES=""
PATCH_CONTENT=""
if [[ -n "$INPUT_PATCH_FILE" && -f "$INPUT_PATCH_FILE" ]]; then
  PATCH_CONTENT=$(cat "$INPUT_PATCH_FILE")
else
  if [[ -f "$CHANGED_FILES_FILE" ]]; then
    CHANGED_FILES=$(cat "$CHANGED_FILES_FILE")
  else
    warn "changed_files.txt not found; proceeding without file list."
  fi
  if [[ -f "$PATCH_FILE_DEFAULT" ]]; then
    PATCH_CONTENT=$(cat "$PATCH_FILE_DEFAULT")
  else
    warn "patch.diff not found; proceeding without unified diff."
  fi
fi

# In full-repo mode, do not include Changed files/patch; provide repository signals and targets
if [[ "$full_repo_mode" == "true" ]]; then
  echo
  echo "## Repository Signals"
  echo "- package.json scripts (subset):"
  if [[ -f package.json ]]; then
    echo '```json'
    jq '{name, scripts}' package.json 2>/dev/null || true
    echo '```'
  fi
  echo "- Source files (top 50):"
  echo '```bash'
  (rg --files src | head -n 50) 2>/dev/null || true
  echo '```'
  echo "- Workflows:"
  echo '```bash'
  (rg --files .github/workflows | head -n 20) 2>/dev/null || true
  echo '```'
  echo
  echo "## Targets"
  echo "- Generate under docs/: README.md, stack.md, architecture/overview.md, architecture/diagram.md, endpoints.md, and modules/*"
  echo "- Keep content concise, accurate, idempotent; avoid churn and TODOs."
  exit 0
fi

# Normal mode: include Changed files + patches
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
