#!/usr/bin/env bash
# /**
#  * Smart Doc — Local Runner (preview mode)
#  * Responsibility:
#  *   - Execute the Smart Doc Action locally in PR-preview mode without creating commits or PRs.
#  *   - Map .env and CLI flags to action inputs and environment variables.
#  *   - Provide developer-friendly iteration on the prompt (template) with options like --base, --include-working, and patch injection via INPUT_PATCH_FILE.
#  * Invariants (keep in future iterations):
#  *   - Never push or create PRs; always simulate a pull_request event.
#  *   - Only require lightweight dependencies (git, jq, curl). No global state mutation beyond the current process.
#  *   - Respect path whitelist implicitly by delegating file writes to the Action/LLM; do not write docs directly here.
#  *   - Keep logs concise with emojis and avoid dumping large diffs to stdout.
#  * Notes:
#  *   - OPENAI_API_KEY is forced from SMART_DOC_API_TOKEN only for this process to avoid conflicts.
#  *   - INPUT_PATCH_FILE can be used to inject a unified diff for testing the prompt builder pipeline.
#  */
# Local runner for Smart Doc: executes the GitHub Action entrypoint in PR-preview mode
# - Loads SMART_DOC_API_TOKEN from .env (mapped to OPENAI_API_KEY)
# - Simulates a pull_request event (no pushes, no PR creation)
# - Uses the repo's prompts/default.md by default so you can iterate on it
#
# Usage:
#   scripts/run-smart-doc-local.sh [--base <branch>] [--docs <folder>] [--prompt <path>] [--history true|false]
# Examples:
#   scripts/run-smart-doc-local.sh
#   scripts/run-smart-doc-local.sh --base develop --prompt prompts/default.md --history false
set -euo pipefail

here_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here_dir/.." && pwd)"
cd "$repo_root"

log() { echo "🧪 [smart-doc-local] $*"; }
err() { echo "❌ [smart-doc-local][error] $*" >&2; }

# --- Parse args ---
BASE_REF="main"
DOCS_FOLDER="docs"
PROMPT_TEMPLATE="prompts/default.md"
GENERATE_HISTORY="true"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_REF="${2:-main}"; shift 2;;
    --docs) DOCS_FOLDER="${2:-docs}"; shift 2;;
    --prompt) PROMPT_TEMPLATE="${2:-prompts/default.md}"; shift 2;;
    --history) GENERATE_HISTORY="${2:-true}"; shift 2;;
    *) err "Unknown arg: $1"; exit 2;;
  esac
done

# --- Check dependencies ---
need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing dependency: $1"; missing=1; }; }
missing=0
need_cmd git
need_cmd jq
need_cmd curl
# gh is optional for PR metadata fetch; entrypoint handles absence gracefully
if [[ $missing -eq 1 ]]; then err "Install missing dependencies and retry."; exit 1; fi

# --- Load .env (expects SMART_DOC_API_TOKEN) ---
if [[ -f .env ]]; then
  # load simple KEY=VALUE lines (ignore comments and blanks)
  set -a
  # shellcheck disable=SC1091
  source <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | sed 's/^export //')
  set +a
  log "Loaded environment from .env"
else
  err ".env not found at repo root. Create it with SMART_DOC_API_TOKEN=..."
  exit 1
fi

if [[ -z "${SMART_DOC_API_TOKEN:-}" ]]; then
  err "SMART_DOC_API_TOKEN is required in .env"
  exit 1
fi
# Preserve any existing OPENAI_API_KEY but force the action to use SMART_DOC_API_TOKEN
ORIGINAL_OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export OPENAI_API_KEY="$SMART_DOC_API_TOKEN"

# --- Simulate GitHub env (pull_request event) ---
# Derive repo slug from git remote
REPO_SLUG="${GITHUB_REPOSITORY:-}"
if [[ -z "$REPO_SLUG" ]]; then
  REPO_SLUG=$(git config --get remote.origin.url | sed -E 's#.*github.com[:/](.+)\.git#\1#')
fi
export GITHUB_EVENT_NAME="pull_request"
export GITHUB_REPOSITORY="$REPO_SLUG"
export GITHUB_BASE_REF="$BASE_REF"
export GITHUB_SHA="$(git rev-parse HEAD)"
GITHUB_EVENT_PATH_FILE=$(mktemp)
printf '{}' > "$GITHUB_EVENT_PATH_FILE"
export GITHUB_EVENT_PATH="$GITHUB_EVENT_PATH_FILE"

# The composite action expects this to resolve the default prompt path
export GITHUB_ACTION_PATH="$repo_root"

# --- Inputs for entrypoint ---
export INPUT_BRANCH="$BASE_REF"
export INPUT_DOCS_FOLDER="$DOCS_FOLDER"
export INPUT_PROMPT_TEMPLATE="$PROMPT_TEMPLATE"
export INPUT_MODEL="${INPUT_MODEL:-gpt-5-nano}"
export INPUT_GENERATE_HISTORY="$GENERATE_HISTORY"
export INPUT_SMART_DOC_API_TOKEN="$SMART_DOC_API_TOKEN"
export INPUT_JIRA_HOST="${INPUT_JIRA_HOST:-}"
export INPUT_JIRA_EMAIL="${INPUT_JIRA_EMAIL:-}"
export INPUT_JIRA_API_TOKEN="${INPUT_JIRA_API_TOKEN:-}"
export INPUT_CLICKUP_TOKEN="${INPUT_CLICKUP_TOKEN:-}"
# merge-related inputs are irrelevant in pull_request mode but set for completeness
export INPUT_MERGE_MODE="off"
export INPUT_MERGE_WAIT_SECONDS="10"
export INPUT_MERGE_MAX_ATTEMPTS="30"
export INPUT_READY_PR_IF_DRAFT="true"

log "Repo: $REPO_SLUG | Base: $BASE_REF | Docs: $DOCS_FOLDER | Prompt: $PROMPT_TEMPLATE | History: $GENERATE_HISTORY"

# --- Run entrypoint (no pushes/PRs in PR mode) ---
# shellcheck disable=SC1091
bash "$repo_root/entrypoint.sh"

log "Run completed. No commits or PRs were created (PR preview mode)."

# Quick summary of generated/changed files (not staged here)
if command -v rg >/dev/null 2>&1; then
  log "Docs tree (top-level):"
  rg -n "^# " -S "$DOCS_FOLDER" || true
fi

log "Changed files preview under docs/:"
(git status --porcelain "$DOCS_FOLDER" || true)

log "If satisfied, commit prompt changes only; Smart Doc changes are previews from this run."
