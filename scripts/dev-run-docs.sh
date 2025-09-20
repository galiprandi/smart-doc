#!/usr/bin/env bash
# Smart Doc — Dev Runner for Doc Generation
# Runs the doc-updater step with a provided prompt into an isolated output folder.
# - Cleans the output folder if --clean is passed
# - Writes docs and SMART_TIMELINE.md into the chosen --docs-out directory
# - Prints a tree of the output folder on completion

set -euo pipefail

log() { echo "🧪 [dev-run] $*"; }
warn() { echo "::warning::⚠️ $*"; }
err() { echo "::error::❌ $*"; }

usage() {
  cat << EOF
Usage: bash scripts/dev-run-docs.sh --prompt <file.md> [--model <id>] [--docs-out <dir>] [--clean]
   or: bash scripts/dev-run-docs.sh --prompts-dir <dir> [--model <id>] [--docs-out <dir>] [--clean]

Options:
  --prompt <file.md>   Prompt file to feed into doc-updater (required unless --prompts-dir)
  --prompts-dir <dir>  Directory containing .md prompts to iterate (mutually exclusive with --prompt)
  --model <id>         Model id (default: gpt-5-nano)
  --docs-out <dir>     Output directory for docs and timeline (default: docs-out)
  --clean              Remove output directory before running

Environment:
  OPENAI_API_KEY or INPUT_SMART_DOC_API_TOKEN should be set for real CLI execution.
EOF
}

PROMPT=""
PROMPTS_DIR=""
MODEL="gpt-5-nano"
DOCS_OUT="docs-out"
CLEAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)
      PROMPT=${2:-}; shift 2 ;;
    --model)
      MODEL=${2:-}; shift 2 ;;
    --docs-out)
      DOCS_OUT=${2:-}; shift 2 ;;
    --clean)
      CLEAN=true; shift ;;
    --prompts-dir)
      PROMPTS_DIR=${2:-}; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      err "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

if [[ -n "$PROMPTS_DIR" && -n "$PROMPT" ]]; then
  err "--prompt and --prompts-dir are mutually exclusive"; usage; exit 2
fi
if [[ -z "$PROMPTS_DIR" && -z "$PROMPT" ]]; then
  err "Either --prompt or --prompts-dir is required"; usage; exit 2
fi
if [[ -n "$PROMPT" && ! -f "$PROMPT" ]]; then
  err "Prompt file not found: $PROMPT"; exit 2
fi
if [[ -n "$PROMPTS_DIR" && ! -d "$PROMPTS_DIR" ]]; then
  err "Prompts directory not found: $PROMPTS_DIR"; exit 2
fi

# Prepare output directory
if [[ "$CLEAN" == true && -d "$DOCS_OUT" ]]; then
  log "Cleaning output directory: $DOCS_OUT"
  rm -rf "$DOCS_OUT"
fi
mkdir -p "$DOCS_OUT/docs"

# Place timeline in same folder as requested
TIMELINE_PATH="$DOCS_OUT/SMART_TIMELINE.md"

# tmp workspace for this run (isolated)
RUN_TMP="$DOCS_OUT/tmp"
mkdir -p "$RUN_TMP"

# Helper to run one prompt
run_one() {
  local prompt_path="$1"
  export INPUT_DOCS_FOLDER="$DOCS_OUT/docs"
  export PROMPT_FILE="$prompt_path"
  export INPUT_MODEL="$MODEL"

  # Ensure timeline writes resolve near CWD; doc-updater checks only docs/ and SMART_TIMELINE.md by path.
  # We symlink a local timeline into repo root for this run and clean it after.
  local symlink_created=false
  if [[ ! -e SMART_TIMELINE.md ]]; then
    ln -s "$(realpath "$TIMELINE_PATH")" SMART_TIMELINE.md || true
    symlink_created=true
  fi

  log "Running doc-updater with model=$MODEL, prompt=$prompt_path, out=$DOCS_OUT"
  set +e
  local out
  out=$(bash "${GITHUB_ACTION_PATH:-.}/scripts/doc-updater.sh" 2>&1)
  local rc=$?
  printf "%s\n" "$out"
  # Copy to clipboard when available (macOS hosts)
  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s\n" "$out" | pbcopy
    echo "📎 Contenido copiado!"
  fi
  set -e

  if [[ "$symlink_created" == true ]]; then
    rm -f SMART_TIMELINE.md || true
  fi
  if [[ $rc -ne 0 ]]; then
    warn "doc-updater exited with code $rc for prompt $prompt_path."
  fi
}

# Single or multiple prompts
if [[ -n "$PROMPTS_DIR" ]]; then
  shopt -s nullglob
  prompts=("$PROMPTS_DIR"/*.md)
  if [[ ${#prompts[@]} -eq 0 ]]; then
    warn "No .md prompts found in $PROMPTS_DIR"
  fi
  for p in "${prompts[@]}"; do
    # For each prompt, we run into the same docs-out; callers can change docs-out per run if they want isolation per prompt
    run_one "$p"
  done
else
  run_one "$PROMPT"
fi

# Print a tree of the output folder
log "Output tree for $DOCS_OUT:"
if command -v tree >/dev/null 2>&1; then
  tree -a "$DOCS_OUT"
else
  # Fallback: find
  find "$DOCS_OUT" -print | sed 's,^,  ,'
fi

log "Done."
