#!/usr/bin/env bash
set -euo pipefail

log() { echo "[smart-doc] $*"; }
warn() { echo "::warning::$*"; }
err() { echo "::error::$*"; }

# Inputs (from composite action env)
INPUT_BRANCH=${INPUT_BRANCH:-main}
INPUT_DOCS_FOLDER=${INPUT_DOCS_FOLDER:-docs}
INPUT_PROMPT_TEMPLATE=${INPUT_PROMPT_TEMPLATE:-}
INPUT_GENERATE_HISTORY=${INPUT_GENERATE_HISTORY:-true}
INPUT_SMART_DOC_API_TOKEN=${INPUT_SMART_DOC_API_TOKEN:-}
INPUT_MODEL=${INPUT_MODEL:-}
INPUT_JIRA_HOST=${INPUT_JIRA_HOST:-}
INPUT_JIRA_EMAIL=${INPUT_JIRA_EMAIL:-}
INPUT_JIRA_API_TOKEN=${INPUT_JIRA_API_TOKEN:-}
INPUT_CLICKUP_TOKEN=${INPUT_CLICKUP_TOKEN:-}

## Auth mapping: only SMART_DOC_API_TOKEN is supported (maps to OPENAI_API_KEY)
if [[ -n "${OPENAI_API_KEY:-}" && -n "$INPUT_SMART_DOC_API_TOKEN" && "$OPENAI_API_KEY" != "$INPUT_SMART_DOC_API_TOKEN" ]]; then
  err "Both OPENAI_API_KEY and SMART_DOC_API_TOKEN are defined with different values. Define ONLY SMART_DOC_API_TOKEN."
  exit 1
fi
if [[ -n "$INPUT_SMART_DOC_API_TOKEN" ]]; then
  export OPENAI_API_KEY="$INPUT_SMART_DOC_API_TOKEN"
fi

# Configure git identity for commits (push events only)
git config --global user.name "GitHub Action"
git config --global user.email "action@github.com"

# Ensure docs folder exists
mkdir -p "$INPUT_DOCS_FOLDER"

# Authentication
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  err "SMART_DOC_API_TOKEN is required (mapped to OPENAI_API_KEY)."
  exit 1
fi
log "Auth configured: OPENAI_API_KEY is set."

# Select model: use user-provided if any; otherwise use temporary default
MODEL="$INPUT_MODEL"
if [[ -n "$MODEL" ]]; then
  log "Using model: $MODEL"
else
  MODEL="gpt-5-nano"
  log "No model specified; using temporary default model: $MODEL"
fi

# Prepare optional MCP settings if any secret present
mkdir -p "$HOME/.qwen"
SETTINGS_PATH="$HOME/.qwen/settings.json"
generate_settings=false
[[ -n "$INPUT_JIRA_HOST" && -n "$INPUT_JIRA_EMAIL" && -n "$INPUT_JIRA_API_TOKEN" ]] && generate_settings=true
[[ -n "$INPUT_CLICKUP_TOKEN" ]] && generate_settings=true

if $generate_settings; then
  log "Generating ~/.qwen/settings.json for MCP integrations (optional)..."
  # Build JSON dynamically to include only provided blocks
  {
    echo '{'
    echo '  "mcpServers": {'
    local first=true
    if [[ -n "$INPUT_JIRA_HOST" && -n "$INPUT_JIRA_EMAIL" && -n "$INPUT_JIRA_API_TOKEN" ]]; then
      if ! $first; then echo ","; fi
      first=false
      cat <<JSON
    "jira": {
      "command": "jira-mcp-server",
      "env": {
        "ATLASSIAN_HOST": "$INPUT_JIRA_HOST",
        "ATLASSIAN_EMAIL": "$INPUT_JIRA_EMAIL",
        "ATLASSIAN_TOKEN": "$INPUT_JIRA_API_TOKEN"
      }
    }
JSON
    fi
    if [[ -n "$INPUT_CLICKUP_TOKEN" ]]; then
      if ! $first; then echo ","; fi
      first=false
      cat <<JSON
    "clickup": {
      "command": "clickup-mcp-server",
      "env": {
        "CLICKUP_TOKEN": "$INPUT_CLICKUP_TOKEN"
      }
    }
JSON
    fi
    echo '  }'
    echo '}'
  } > "$SETTINGS_PATH"
else
  # No MCP configured; ensure prior settings do not cause confusion
  if [[ -f "$SETTINGS_PATH" ]]; then rm -f "$SETTINGS_PATH"; fi
fi

# Determine changed files range using GitHub API via gh
EVENT_NAME=${GITHUB_EVENT_NAME:-push}
REPO=${GITHUB_REPOSITORY}
if [[ "$EVENT_NAME" == "pull_request" ]]; then
  BASE=${GITHUB_BASE_REF}
  HEAD=${GITHUB_SHA}
  CHANGED_FILES=$(gh api \
    repos/${REPO}/compare/${BASE}...${HEAD} \
    --jq '.files[].filename' 2>/dev/null || true)
else
  BASE=$(jq -r '.before // empty' "$GITHUB_EVENT_PATH" || true)
  HEAD=${GITHUB_SHA}
  if [[ -n "$BASE" ]]; then
    CHANGED_FILES=$(gh api \
      repos/${REPO}/compare/${BASE}...${HEAD} \
      --jq '.files[].filename' 2>/dev/null || true)
  else
    # First commit on branch: include all tracked files
    CHANGED_FILES=$(git ls-files || true)
  fi
fi

if [[ -z "${CHANGED_FILES//[[:space:]]/}" ]]; then
  log "No changed files detected. Nothing to document."
  exit 0
fi

log "Changed files:\n$CHANGED_FILES"

# Build prompt
PROMPT_FILE=$(mktemp)
if [[ -n "$INPUT_PROMPT_TEMPLATE" && -f "$INPUT_PROMPT_TEMPLATE" ]]; then
  cat "$INPUT_PROMPT_TEMPLATE" > "$PROMPT_FILE"
else
  # Use default prompt packaged with the action
  cat "${GITHUB_ACTION_PATH}/prompts/default.md" > "$PROMPT_FILE"
fi

{
  echo
  echo "---"
  echo "Changed files:"; echo "$CHANGED_FILES"
  echo "Docs folder: $INPUT_DOCS_FOLDER"
  echo "Generate HISTORY.md: $INPUT_GENERATE_HISTORY"
} >> "$PROMPT_FILE"

openai_generate() {
  local prompt_file="$1"
  local model_flag
  if [[ -n "$MODEL" ]]; then
    model_flag="$MODEL"
  else
    model_flag="gpt-5-nano"
  fi
  # Strip optional provider prefix like 'openai:' if present
  if [[ "$model_flag" == openai:* ]]; then
    model_flag="${model_flag#openai:}"
  fi
  log "Calling OpenAI Responses API with model: $model_flag"
  local response_file
  response_file=$(mktemp)
  curl -sS https://api.openai.com/v1/responses \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d @<(jq -n --arg m "$model_flag" --arg p "$(sed 's/\\/\\\\/g' "$prompt_file" | sed 's/"/\\"/g')" '{model:$m, input:$p}') \
    > "$response_file"
  local output
  output=$(jq -r '(.output_text // .choices[0].message.content // .data[0].text // empty)' "$response_file") || true
  if [[ -z "$output" || "$output" == "null" ]]; then
    warn "OpenAI response contained no output. Showing first 200 lines:"
    sed -n '1,200p' "$response_file" || true
    return 1
  fi
  mkdir -p "$INPUT_DOCS_FOLDER"
  printf "%s\n" "$output" > "$INPUT_DOCS_FOLDER/README.md"
  log "Wrote generated content to $INPUT_DOCS_FOLDER/README.md"
}

log "Running Smart Doc with OpenAI (Responses API)..."
if ! openai_generate "$PROMPT_FILE"; then
  warn "OpenAI generation failed; seeding minimal docs if not present."
  if [[ ! -f "$INPUT_DOCS_FOLDER/README.md" ]]; then
    cat > "$INPUT_DOCS_FOLDER/README.md" << 'EOSEED'
# Project Documentation

This is an auto-generated documentation seed. Content generation failed or produced no output.

- Architecture: see ./architecture/overview.md
- Stack: see ./stack.md
- Modules: see ./modules/
EOSEED
  fi
fi

# Optionally generate/update HISTORY.md marker if requested and file missing
if [[ "${INPUT_GENERATE_HISTORY,,}" == "true" ]]; then
  if [[ ! -f "HISTORY.md" ]]; then
    echo -e "# HISTORY\n" > HISTORY.md
  fi
fi

# Stage, commit, push only on push events
if [[ "$EVENT_NAME" == "pull_request" ]]; then
  warn "Pull request event detected: will not push changes. Review artifacts in the PR run."
  # Optional: comment summary on PR
  if command -v jq >/dev/null 2>&1; then
    PR_NUMBER=$(jq -r '.pull_request.number // empty' "$GITHUB_EVENT_PATH" || true)
    if [[ -n "$PR_NUMBER" ]]; then
      SUMMARY_BODY=$(printf "Smart Doc analyzed these files:\n\n%s\n\nNote: No commits were pushed on PR runs. Preview is attached as artifact (if any)." "$CHANGED_FILES")
      gh pr comment "$PR_NUMBER" --body "$SUMMARY_BODY" >/dev/null 2>&1 || true
    fi
  fi
  exit 0
fi

git add -A
if git diff --cached --quiet; then
  log "No documentation changes to commit."
  exit 0
fi

git commit -m "docs: update documentation via Smart Doc"
git push || warn "Git push failed (possibly due to permissions)."

log "Smart Doc completed successfully."
