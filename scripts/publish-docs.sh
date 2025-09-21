#!/usr/bin/env bash
set -euo pipefail

log() { echo "[publish-docs] $1"; }

# Skip if last commit was by bot (avoid loops)
LAST_AUTHOR="$(git log -1 --pretty=%an 2>/dev/null || true)"
if [ "$LAST_AUTHOR" = "smart-doc[bot]" ]; then
  log "🔁 Last commit by bot; exiting"
  exit 0
fi

# Stage candidate outputs and verify there are changes
git add docs SMART_TIMELINE.md 2>/dev/null || true
if git diff --cached --quiet; then
  log "ℹ️ No docs changes to publish; exiting"
  exit 0
fi

EVENT_NAME="${GITHUB_EVENT_NAME:-}"
REF_NAME="${GITHUB_REF_NAME:-}"
HEAD_REF="${GITHUB_HEAD_REF:-}"
SHA_SHORT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

# Detect fork on PR using event payload if present
IS_FORK="false"
if [ "$EVENT_NAME" = "pull_request" ] && [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
  if command -v jq >/dev/null 2>&1; then
    IS_FORK="$(jq -r '.pull_request.head.repo.fork' "$GITHUB_EVENT_PATH" 2>/dev/null || echo false)"
  fi
fi

git config user.name "smart-doc[bot]"
git config user.email "smart-doc[bot]@users.noreply.github.com"

# Collect staged doc files for reporting (before committing)
CHANGED_FILES=$(git diff --cached --name-only -- 'docs/**' 'SMART_TIMELINE.md' 2>/dev/null || true)

post_pr_comment() {
  # Requires: gh CLI, GITHUB_EVENT_PATH JSON file
  [ "$EVENT_NAME" = "pull_request" ] || return 0
  [ -n "$CHANGED_FILES" ] || { log "ℹ️ No changed files to report"; return 0; }
  if ! command -v gh >/dev/null 2>&1; then
    log "⚠️ gh not available; cannot post PR comment"
    return 0
  fi
  if [ -z "${GITHUB_EVENT_PATH:-}" ] || [ ! -f "$GITHUB_EVENT_PATH" ]; then
    log "⚠️ GITHUB_EVENT_PATH missing; cannot determine PR number"
    return 0
  fi
  local pr_number
  pr_number=$(jq -r '.number // .pull_request.number // empty' "$GITHUB_EVENT_PATH" 2>/dev/null || true)
  [ -n "$pr_number" ] || { log "⚠️ Could not resolve PR number"; return 0; }

  # Build concise comment body
  local body
  body="📚 Smart Doc — updated documentation files:\n\n"
  while IFS= read -r f; do
    [ -n "$f" ] && body+="- 📄 $f\n"
  done <<< "$CHANGED_FILES"

  gh pr comment "$pr_number" --body "$body" &&
    log "💬 Posted PR comment with updated files" ||
    log "⚠️ Failed to post PR comment"
}

case "$EVENT_NAME" in
  pull_request)
    if [ "$IS_FORK" = "true" ]; then
      log "🧪 PR from fork detected; skipping push (use artifact in workflow)"
      post_pr_comment || true
      exit 0
    fi
    TARGET_BRANCH="${HEAD_REF:-$(git rev-parse --abbrev-ref HEAD)}"
    log "✍️ Committing to PR head branch: $TARGET_BRANCH"
    git commit -m "docs: update generated docs"
    git push origin "HEAD:${TARGET_BRANCH}"
    post_pr_comment || true
    ;;
  push)
    if [ "${REF_NAME:-}" = "main" ] || [ "${REF_NAME:-}" = "master" ]; then
      NEW_BRANCH="smart-doc/docs-update-${SHA_SHORT}"
      log "🚀 Creating docs PR from $NEW_BRANCH"
      git checkout -b "$NEW_BRANCH"
      git commit -m "docs: update generated docs"
      git push -u origin "$NEW_BRANCH"
      if command -v gh >/dev/null 2>&1; then
        gh pr create --fill --title "docs: update generated docs ($SHA_SHORT)" \
          --body "Automated docs update from Smart Doc." --label "docs,automated" || \
          log "⚠️ gh pr create failed"
      else
        log "⚠️ gh not found; pushed branch without opening PR"
      fi
    else
      CURRENT_BRANCH="${REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
      log "✍️ Committing to branch: $CURRENT_BRANCH"
      git commit -m "docs: update generated docs"
      git push origin "HEAD:${CURRENT_BRANCH}"
    fi
    ;;
  *)
    log "ℹ️ Unsupported event ($EVENT_NAME); skipping"
    ;;
esac
