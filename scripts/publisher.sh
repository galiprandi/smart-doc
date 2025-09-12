#!/usr/bin/env bash
# /**
#  * Smart Doc — Publisher
#  * Responsibility:
#  *   - If running on push event and there are documentation changes, create/update a PR.
#  *   - On pull_request events, do nothing (no push, no PR).
#  * Invariants (keep in future iterations):
#  *   - Never write docs; only git/gh operations.
#  *   - Read change signal from tmp/have_changes.flag.
#  *   - Keep logs concise with emojis.
#  */
set -euo pipefail

log() { echo "🚀 [publisher] $*"; }
warn() { echo "::warning::⚠️ $*"; }
err() { echo "::error::❌ $*"; }

EVENT_NAME=${GITHUB_EVENT_NAME:-push}
TMP_DIR="tmp"
CHANGES_FLAG="$TMP_DIR/have_changes.flag"

if [[ "$EVENT_NAME" == "pull_request" ]]; then
  log "Pull request event: publishing is skipped."
  exit 0
fi

if [[ ! -f "$CHANGES_FLAG" ]]; then
  warn "Change flag not found. Assuming no changes to publish."
  exit 0
fi

if [[ "$(cat "$CHANGES_FLAG" 2>/dev/null || echo no)" != "yes" ]]; then
  log "No changes to publish."
  exit 0
fi

# Reuse logic from entrypoint for PR creation
SHORT_SHA=$(printf "%s" "${GITHUB_SHA:-$(git rev-parse HEAD | cut -c1-7)}" | cut -c1-7)
TARGET_BRANCH="${INPUT_BRANCH:-main}"
UPDATE_BRANCH="smart-doc/docs-update-${SHORT_SHA}"

log "Creating update branch: $UPDATE_BRANCH (target: $TARGET_BRANCH)"
# Ensure we have the latest refs from origin and base our update branch on remote if it exists
git fetch --prune origin || true
if git rev-parse --verify "origin/$UPDATE_BRANCH" >/dev/null 2>&1; then
  git checkout -B "$UPDATE_BRANCH" "origin/$UPDATE_BRANCH"
else
  git switch -c "$UPDATE_BRANCH" || git checkout -b "$UPDATE_BRANCH"
fi

git add -A || true
git commit -m "docs: update documentation via Smart Doc" || true

if ! git push -u origin "$UPDATE_BRANCH"; then
  warn "Initial push failed (likely non fast-forward). Attempting force-with-lease..."
  git fetch origin "$UPDATE_BRANCH" || true
  git push -u --force-with-lease origin "$UPDATE_BRANCH" || { warn "Push failed; aborting publish."; exit 0; }
fi

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
REPO_SLUG="${GITHUB_REPOSITORY:-}"
if [[ -z "$REPO_SLUG" ]]; then
  REPO_SLUG=$(git config --get remote.origin.url | sed -E 's#.*github.com[:/](.+)\.git#\1#')
fi

PR_URL=""
if PR_URL=$(gh pr create --repo "$REPO_SLUG" --base "$TARGET_BRANCH" --head "$UPDATE_BRANCH" \
  --title "docs: update via Smart Doc ($SHORT_SHA)" \
  --body "Auto-generated documentation updates for commit ${GITHUB_SHA:-$SHORT_SHA}" 2>/dev/null); then
  log "Opened PR: $PR_URL"
else
  warn "PR creation failed; attempting to find existing PR for $UPDATE_BRANCH"
  PR_URL=$(gh pr list --repo "$REPO_SLUG" --head "$UPDATE_BRANCH" --json url --jq '.[0].url' 2>/dev/null || true)
  if [[ -n "$PR_URL" ]]; then
    log "Found existing PR: $PR_URL"
  else
    warn "No PR found for $UPDATE_BRANCH. Ensure permissions or provide GH_TOKEN."
  fi
fi

# Optionally attempt auto-merge/immediate based on inputs (reuse logic later if needed)
log "Publish step completed."

exit 0
