#!/usr/bin/env bash
# Run Smart Doc dev runner inside the Ubuntu Docker image, passing through your local API key
# Usage examples:
#   bash scripts/dev-run-docker.sh --prompt prompts/default.md --docs-out docs-out --clean
#   bash scripts/dev-run-docker.sh --prompts-dir prompts --docs-out evals --clean

set -euo pipefail

log() { echo "🐳 [dev-docker] $*"; }
err() { echo "::error::❌ $*"; }

IMAGE_NAME=${IMAGE_NAME:-smart-doc-dev}

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  log "Building image $IMAGE_NAME..."
  docker build -t "$IMAGE_NAME" .
fi

# Prefer OPENAI_API_KEY, fallback to INPUT_SMART_DOC_API_TOKEN
API_KEY="${OPENAI_API_KEY:-${INPUT_SMART_DOC_API_TOKEN:-}}"
if [[ -z "$API_KEY" ]]; then
  err "OPENAI_API_KEY or INPUT_SMART_DOC_API_TOKEN is not set in your shell. Export one and retry."; exit 2
fi

# Pass through args to the inner script
RUN_CMD=(bash scripts/dev-run-docs.sh "$@")

log "Running container with mounted repo and API key..."
OUT=$(docker run --rm \
  -e OPENAI_API_KEY="$API_KEY" \
  -v "$PWD":/app \
  -w /app \
  "$IMAGE_NAME" \
  "${RUN_CMD[@]}" 2>&1)
RC=$?
printf "%s\n" "$OUT"
if command -v pbcopy >/dev/null 2>&1; then
  printf "%s\n" "$OUT" | pbcopy
  echo "📎 Contenido copiado!"
fi
exit $RC
