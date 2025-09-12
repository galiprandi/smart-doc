#!/usr/bin/env bash
# /**
#  * Smart Doc — Diff Detector
#  * Responsibility:
#  *   - Determine the set of changed files and a unified diff for the current run.
#  *   - Prefer local git resolution (merge-base with INPUT_BRANCH), optionally include working tree changes.
#  *   - Support injected unified diff via INPUT_PATCH_FILE for test/preview scenarios.
#  *   - Soft-skip when there are no changes (exit 0, write empty outputs).
#  * Invariants (keep in future iterations):
#  *   - Produce outputs only under tmp/: changed_files.txt and patch.diff.
#  *   - Keep logs concise with emojis.
#  * Inputs: INPUT_BRANCH, INPUT_INCLUDE_WORKING, INPUT_PATCH_FILE.
#  */
set -euo pipefail

log() { echo "🔎 [diff-detector] $*"; }
warn() { echo "::warning::⚠️ $*"; }
err() { echo "::error::❌ $*"; }

INPUT_BRANCH=${INPUT_BRANCH:-main}
INPUT_INCLUDE_WORKING=${INPUT_INCLUDE_WORKING:-false}
INPUT_PATCH_FILE=${INPUT_PATCH_FILE:-}
EVENT_NAME=${GITHUB_EVENT_NAME:-}
BASE_REF_ENV=${GITHUB_BASE_REF:-}

TMP_DIR="tmp"
mkdir -p "$TMP_DIR"
FILES_OUT="$TMP_DIR/changed_files.txt"
PATCH_OUT="$TMP_DIR/patch.diff"
: > "$FILES_OUT"
: > "$PATCH_OUT"

# 1) Injected patch (test mode) takes precedence
if [[ -n "$INPUT_PATCH_FILE" && -f "$INPUT_PATCH_FILE" ]]; then
  log "Using injected patch: $INPUT_PATCH_FILE"
  awk '
    /^diff --git a\//{a=$3; b=$4; sub("a/","",a); sub("b/","",b); print a; print b}
    /^\+\+\+ /{if($2!="/dev/null"){p=$2; sub("b/","",p); sub("a/","",p); print p}}
    /^--- /{if($2!="/dev/null"){m=$2; sub("a/","",m); sub("b/","",m); print m}}
  ' "$INPUT_PATCH_FILE" | sed 's#^a/##; s#^b/##' | sed '/^$/d' | sort -u > "$FILES_OUT" || true
  cat "$INPUT_PATCH_FILE" > "$PATCH_OUT"
fi

# 2) Local git resolution (only if no injected patch)
if [[ ! -s "$PATCH_OUT" ]]; then
  BASE_LOCAL=""
  # Prefer PR base when available
  if [[ "$EVENT_NAME" == "pull_request" && -n "$BASE_REF_ENV" ]]; then
    if git rev-parse --verify "$BASE_REF_ENV" >/dev/null 2>&1; then
      BASE_LOCAL=$(git merge-base "$BASE_REF_ENV" HEAD || true)
    fi
  fi
  # Otherwise, use configured INPUT_BRANCH
  if [[ -z "$BASE_LOCAL" && -n "$INPUT_BRANCH" ]]; then
    if git rev-parse --verify "$INPUT_BRANCH" >/dev/null 2>&1; then
      BASE_LOCAL=$(git merge-base "$INPUT_BRANCH" HEAD || true)
    fi
  fi
  # If merge-base equals HEAD (e.g., push on base branch), fallback to HEAD~1
  HEAD_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
  if [[ -n "$BASE_LOCAL" && -n "$HEAD_SHA" && "$BASE_LOCAL" == "$HEAD_SHA" ]]; then
    BASE_LOCAL=$(git rev-parse HEAD~1 2>/dev/null || echo "")
  fi
  # Final fallback
  if [[ -z "$BASE_LOCAL" ]]; then
    BASE_LOCAL=$(git rev-parse HEAD~1 2>/dev/null || true)
  fi
  if [[ -n "$BASE_LOCAL" ]]; then
    if [[ "$INPUT_INCLUDE_WORKING" == "true" ]]; then
      git diff --name-only "$BASE_LOCAL"... -- | tr -d '\r' > "$FILES_OUT" || true
      git diff -U3 "$BASE_LOCAL"... > "$PATCH_OUT" || true
    else
      git diff --name-only "$BASE_LOCAL"...HEAD | tr -d '\r' > "$FILES_OUT" || true
      git diff -U3 "$BASE_LOCAL"...HEAD > "$PATCH_OUT" || true
    fi
  else
    # New repo fallback: list tracked files only (empty patch)
    git ls-files > "$FILES_OUT" || true
  fi
fi

CHANGED_COUNT=$(wc -l < "$FILES_OUT" | tr -d ' ' || echo 0)
PATCH_SIZE=$(wc -c < "$PATCH_OUT" | tr -d ' ' || echo 0)
log "files=$CHANGED_COUNT, patch_bytes=$PATCH_SIZE"

exit 0
