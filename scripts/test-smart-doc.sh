#!/usr/bin/env bash
# /**
#  * Smart Doc — Test Runner (local preview)
#  * Responsibility:
#  *   - Run a local Smart Doc preview using a repo-related test patch by default.
#  *   - Provide convenient flags to override the patch file and include working tree changes.
#  * Invariants (keep in future iterations):
#  *   - No commits or PRs; preview-only.
#  *   - Keep logs concise with emojis; do not dump large diffs.
#  *   - Delegate all behavior to the existing local runner `scripts/run-smart-doc-local.sh`.
#  */
set -euo pipefail

here_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here_dir/.." && pwd)"
cd "$repo_root"

log() { echo "🧪 [smart-doc-test] $*"; }
err() { echo "❌ [smart-doc-test][error] $*" >&2; }

PATCH_FILE_DEFAULT="scripts/fixtures/test.patch"
PATCH_FILE="$PATCH_FILE_DEFAULT"
INCLUDE_WORKING="false"
BASE_REF="${INPUT_BRANCH:-main}"
PROMPT_TEMPLATE="${INPUT_PROMPT_TEMPLATE:-prompts/default.md}"
DOCS_FOLDER="${INPUT_DOCS_FOLDER:-docs}"

usage() {
  cat <<USAGE
Usage: scripts/test-smart-doc.sh [--patch <file>] [--include-working] [--base <branch>] [--docs <dir>] [--template <path>]

Options:
  --patch <file>         Unified diff to inject (default: $PATCH_FILE_DEFAULT)
  --include-working      Include uncommitted working tree changes
  --base <branch>        Base branch for diff (default: $BASE_REF)
  --docs <dir>           Docs folder (default: $DOCS_FOLDER)
  --template <path>      Prompt template (default: $PROMPT_TEMPLATE)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --patch) PATCH_FILE="${2:-}"; shift 2;;
    --include-working) INCLUDE_WORKING="true"; shift 1;;
    --base) BASE_REF="${2:-main}"; shift 2;;
    --docs) DOCS_FOLDER="${2:-docs}"; shift 2;;
    --template) PROMPT_TEMPLATE="${2:-prompts/default.md}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) err "Unknown arg: $1"; usage; exit 2;;
  esac
done

if [[ ! -f "$PATCH_FILE" ]]; then
  err "Patch file not found: $PATCH_FILE"
  exit 1
fi

log "Running local preview with patch=$PATCH_FILE include-working=$INCLUDE_WORKING base=$BASE_REF"

# Delegate to the local runner
CMD=(bash scripts/run-smart-doc-local.sh --patch "$PATCH_FILE" --base "$BASE_REF" --docs "$DOCS_FOLDER" --prompt "$PROMPT_TEMPLATE")
if [[ "$INCLUDE_WORKING" == "true" ]]; then
  CMD+=(--include-working)
fi
"${CMD[@]}"

log "Done. Review tmp/prompt.md and changes under $DOCS_FOLDER/."
