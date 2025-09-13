#!/usr/bin/env bash
# Smart Doc — Post PR Comment (single-responsibility)
# Purpose: Comment on the current PR with the list of documentation files added/modified.
# Requirements: Runs inside GitHub Actions on pull_request. Requires gh, jq, GH_TOKEN.

set -euo pipefail

log() { echo "📝 [smart-doc] $*"; }
warn() { echo "::warning::⚠️ $*"; }
err() { echo "::error::❌ $*"; }

# Inputs / environment
INPUT_DOCS_FOLDER=${INPUT_DOCS_FOLDER:-docs}
GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME:-}
GITHUB_EVENT_PATH=${GITHUB_EVENT_PATH:-}
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-}

# Only for PR events
if [[ "$GITHUB_EVENT_NAME" != "pull_request" ]]; then
  warn "post-pr-comment: skipping (event is not pull_request)"
  exit 0
fi

if [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]]; then
  warn "post-pr-comment: GH_TOKEN/GITHUB_TOKEN not set; cannot authenticate gh"
  exit 0
fi

# Ensure gh uses a token
export GH_TOKEN=${GH_TOKEN:-${GITHUB_TOKEN:-}}

# Read PR number from the event payload
if [[ -n "$GITHUB_EVENT_PATH" && -f "$GITHUB_EVENT_PATH" ]]; then
  PR_NUMBER=$(jq -r '.pull_request.number // empty' "$GITHUB_EVENT_PATH")
else
  PR_NUMBER=""
fi

if [[ -z "$PR_NUMBER" ]]; then
  warn "post-pr-comment: could not determine PR number"
  exit 0
fi

# Fetch PR files and keep only docs-related added/modified
# Status mapping to emojis: added=➕ added, modified=✏️ modified
FILE_LINES=$(gh api \
  "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/files" \
  --paginate | \
  jq -r --arg df "$INPUT_DOCS_FOLDER" '
    .[]
    | select((.status=="added" or .status=="modified"))
    | select((.filename|startswith($df + "/")) or (.filename=="SMART_TIMELINE.md"))
    | "- \"" + (if .status=="added" then "➕ added" else "✏️ modified" end) + "\": " + .filename
  ')

TOTAL=$(printf "%s\n" "${FILE_LINES}" | grep -c '^-' || true)

COMMENT_FILE=$(mktemp)
if [[ -n "${FILE_LINES}" ]]; then
  {
    echo "📚 Smart Doc — change-only docs from your diffs"
    echo
    echo "The following documentation files were added or updated (${TOTAL}):"
    echo "${FILE_LINES}"
    echo
    echo "🔍 Source: pulls.listFiles"
    echo
    echo "✅ Keep shipping — we’ll handle the docs. Powered by Smart Doc."
  } > "$COMMENT_FILE"
else
  {
    echo "ℹ️ No documentation changes detected in this run."
    echo
    echo "✅ Keep shipping — we’ll handle the docs. Powered by Smart Doc."
  } > "$COMMENT_FILE"
fi

log "Posting PR comment (PR #$PR_NUMBER)"
# Post the comment
gh pr comment "$PR_NUMBER" --body-file "$COMMENT_FILE" || warn "post-pr-comment: failed to post PR comment"
