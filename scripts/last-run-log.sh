#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
WF_NAME="${2:-📚 Smart Doc}"

if ! command -v gh >/dev/null 2>&1; then
  echo "[last-run-log] gh CLI not found. Install from https://cli.github.com/" >&2
  exit 1
fi

RUN_ID=$(gh run list --branch "$BRANCH" --workflow "$WF_NAME" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)

if [ -z "${RUN_ID:-}" ] || [ "$RUN_ID" = "null" ]; then
  echo "[last-run-log] No runs found for workflow '$WF_NAME' on branch '$BRANCH'" >&2
  exit 1
fi

echo "[last-run-log] Showing logs for run $RUN_ID (branch: $BRANCH, workflow: $WF_NAME)"
gh run view "$RUN_ID" --log

