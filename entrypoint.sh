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

## Note: model selection and MCP config removed for Codex CLI path

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

# Append unified diffs for precise, change-only documentation context
if command -v gh >/dev/null 2>&1 && [[ -n "$REPO" && -n "$HEAD" ]]; then
  if [[ -n "$BASE" ]]; then
    echo >> "$PROMPT_FILE"
    echo "Changed patches (unified diff):" >> "$PROMPT_FILE"
    while IFS= read -r row; do
      f=$(echo "$row" | base64 --decode | jq -r '.filename')
      s=$(echo "$row" | base64 --decode | jq -r '.status')
      p=$(echo "$row" | base64 --decode | jq -r '.patch // ""')
      echo >> "$PROMPT_FILE"
      echo "FILE: $f (status: $s)" >> "$PROMPT_FILE"
      echo '```diff' >> "$PROMPT_FILE"
      printf "%s\n" "$p" >> "$PROMPT_FILE"
      echo '```' >> "$PROMPT_FILE"
    done < <(gh api repos/${REPO}/compare/${BASE}...${HEAD} --jq '.files[] | {filename, status, patch: (.patch // "")} | @base64' 2>/dev/null || true)
  fi
fi

## Flag to detect if generation produced any file content
DID_GENERATE=0

openai_generate() {
  local prompt_file="$1"
  local model_flag
  if [[ -n "$INPUT_MODEL" ]]; then
    model_flag="$INPUT_MODEL"
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
  output=$(jq -r '
    ( .output_text //
      ( .output[]? | .content[]? | select(.type=="output_text") | .text ) //
      .choices[0]?.message?.content //
      .data[0]?.text // empty )' "$response_file") || true
  if [[ -z "$output" || "$output" == "null" ]]; then
    warn "OpenAI response contained no output. Showing first 200 lines:"
    sed -n '1,200p' "$response_file" || true
    return 1
  fi
  mkdir -p "$INPUT_DOCS_FOLDER"
  # If output contains file markers, split into files; else write to README
  local tmpout
  tmpout=$(mktemp)
  printf "%s\n" "$output" > "$tmpout"
  if grep -q '^=== FILE: ' "$tmpout"; then
    local current=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^===\ FILE:\ (.+)\ ===$ ]]; then
        path="${BASH_REMATCH[1]}"
        [[ "$path" == /* ]] && path="${path#/}"
        if [[ "$path" != docs/* && "$path" != HISTORY.md ]]; then
          path="$INPUT_DOCS_FOLDER/$path"
        fi
        path="${path//../}"
        mkdir -p "$(dirname "$path")"
        current="$path"
        : > "$current"
        continue
      fi
      if [[ -n "$current" ]]; then
        printf '%s\n' "$line" >> "$current"
      fi
    done < "$tmpout"
    DID_GENERATE=1
    log "Wrote files from markers under $INPUT_DOCS_FOLDER (and HISTORY.md if present)."
  else
    printf "%s\n" "$output" > "$INPUT_DOCS_FOLDER/README.md"
    DID_GENERATE=1
    log "Wrote generated content to $INPUT_DOCS_FOLDER/README.md"
  fi
}

log "Running Smart Doc with OpenAI Codex CLI..."
run_codex() {
  local prompt
  prompt="$(cat "$PROMPT_FILE")"
  # Request write-enabled sandbox for Codex CLI
  export CODEX_SANDBOX="workspace-write"
  export CODEX_REASONING_EFFORT="medium"
  log "Invoking Codex with sandbox=$CODEX_SANDBOX"
  set +e
  if command -v code >/dev/null 2>&1; then
    code exec --sandbox "$CODEX_SANDBOX" "$prompt" && return 0
  fi
  if command -v codex >/dev/null 2>&1; then
    codex exec --sandbox "$CODEX_SANDBOX" "$prompt" && return 0
  fi
  npx -y @openai/codex exec --sandbox "$CODEX_SANDBOX" "$prompt" && return 0
  set -e
  return 1
}
if ! run_codex; then
  warn "Codex CLI execution failed; no documentation changes will be made."
fi

# Do not auto-create HISTORY.md; rely on tool output

# Stage and commit; create PR with auto-merge on push events
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

# For protected branches, open a PR with auto-merge instead of pushing to main
SHORT_SHA=$(printf "%s" "$GITHUB_SHA" | cut -c1-7)
TARGET_BRANCH="${INPUT_BRANCH:-main}"
UPDATE_BRANCH="smart-doc/docs-update-${SHORT_SHA}"

log "Creating update branch: $UPDATE_BRANCH (target: $TARGET_BRANCH)"
git switch -c "$UPDATE_BRANCH" || git checkout -b "$UPDATE_BRANCH"

if ! git push -u origin "$UPDATE_BRANCH"; then
  warn "Failed to push update branch. Exiting without PR creation."
  exit 0
fi

# Create or reuse PR
PR_URL=""
if PR_URL=$(gh pr create --base "$TARGET_BRANCH" --head "$UPDATE_BRANCH" \
  --title "docs: update via Smart Doc ($SHORT_SHA)" \
  --body "Auto-generated documentation updates for commit $GITHUB_SHA" 2>/dev/null); then
  log "Opened PR: $PR_URL"
else
  warn "PR creation failed; attempting to find existing PR for $UPDATE_BRANCH"
  PR_URL=$(gh pr list --head "$UPDATE_BRANCH" --json url --jq '.[0].url' 2>/dev/null || true)
  if [[ -n "$PR_URL" ]]; then
    log "Found existing PR: $PR_URL"
  else
    warn "No PR found for $UPDATE_BRANCH."
  fi
fi

# Try to enable auto-merge (squash); ignore if not permitted
if [[ -n "$PR_URL" ]]; then
  gh pr merge --auto --squash "$PR_URL" >/dev/null 2>&1 || warn "Auto-merge not enabled or failed."
fi

log "Smart Doc completed (branch: $UPDATE_BRANCH${PR_URL:+, PR: $PR_URL})."
