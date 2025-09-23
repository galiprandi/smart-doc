#!/usr/bin/env bash
set -Eeuo pipefail

# Soft-fail: never break CI/hooks; just print a friendly message
trap 'echo "[smart-doc] ℹ️ Soft-fail (bootstrap) — pipeline continues"; exit 0' ERR

echo "[bootstrap] Smart Doc bootstrap"

if [ -n "${GITHUB_ACTION_PATH:-}" ]; then
  BASE="${GITHUB_ACTION_PATH}"
  echo "[bootstrap] Detected GitHub Actions context (BASE=$BASE)"
else
  echo "[bootstrap] Standalone mode — fetching Smart Doc artifacts"
  TMP_DIR="$(mktemp -d -t smart-doc-XXXXXX)"
  cleanup() { rm -rf "$TMP_DIR"; echo "[bootstrap] Cleaned up temp"; }
  trap cleanup EXIT
  BASE="$TMP_DIR"
  # Fetch latest release tag from GitHub API
  LATEST_TAG=$(curl -s https://api.github.com/repos/galiprandi/smart-doc/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')
  if [ -z "$LATEST_TAG" ]; then
    echo "[bootstrap] Failed to fetch latest tag, falling back to v1"
    LATEST_TAG="v1"
  fi
  REPO_RAW="https://raw.githubusercontent.com/galiprandi/smart-doc/$LATEST_TAG"
  curl -fsSL "$REPO_RAW/smart-doc.sh" -o "$BASE/smart-doc.sh"
  chmod +x "$BASE/smart-doc.sh"
  mkdir -p "$BASE/prompts"
  curl -fsSL "$REPO_RAW/prompts/docs.md" -o "$BASE/prompts/docs.md"
  export GITHUB_ACTION_PATH="$BASE"
fi

# Hint the script to use this prompt explicitly
export SMART_DOC_PROMPT="${GITHUB_ACTION_PATH}/prompts/docs.md"

echo "[bootstrap] Running Smart Doc..."
bash "${GITHUB_ACTION_PATH}/smart-doc.sh"

