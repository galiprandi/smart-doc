#!/usr/bin/env bash
set -euo pipefail

log() {
    echo -e " [smart-doc] $1"
}

# Function to setup inputs
setup_inputs() {
  log "⚙️ Setting environment"
    BRANCH="${INPUT_BRANCH:-main}"
    MINI_MODE="${INPUT_MINI_MODE:-${MINI_MODE:-on}}"  # on|off
    OUTPUT_MODE="${INPUT_OUTPUT_MODE:-${OUTPUT_MODE:-pr}}"  # pr|log
    OPENAI_API_KEY="${INPUT_SMART_DOC_API_TOKEN:-${OPENAI_API_KEY:-}}"
    PROVIDER="${INPUT_PROVIDER:-${PROVIDER:-codex}}"  # codex|ollama|openai
    MODEL="${INPUT_MODEL:-${MODEL:-gpt-5-nano}}"
    OPENAI_BASE_URL="${INPUT_OPENAI_BASE_URL:-${OPENAI_BASE_URL:-}}"

    TIMELINE="SMART_TIMELINE.md"
    TMP_DIR=tmp; mkdir -p "$TMP_DIR"
}

# Install Codex CLI globally or fail
install_codex_globally() {
    log "📦 Installing LLM CLI"
    if command -v codex >/dev/null 2>&1; then
        log "✅ LLM CLI already installed globally"
        return 0
    fi
    log "📦 Installing LLM CLI globally..."
    if ! npm install -g @openai/codex; then
        log "❌ Failed to install LLM CLI" >&2
        return 1
    fi
    log "✅ LLM CLI installed successfully"
}

# Function to run LLM with given prompts (concatenated)
run_llm() {
    local start_time=$(date +%s)
    log "📚 Start documentation process"

    if ! cat "$@" | codex mode exec --full-auto -m gpt-5-mini; then
        log "❌ Failed to run LLM exec mode" >&2
        return 1
    fi
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    log "✅ Documentation process completed successfully"
    log "Time taken: ${elapsed}s"
}

# Main function to orchestrate everything
main() {
  log "✳️  Entrypoint"
    setup_inputs

    # Install Codex globally or fail
    if ! install_codex_globally; then
        echo "❌ [smart-doc] Failed to install Codex CLI" >&2
        exit 1
    fi

    # Run LLM with docs prompt
    if ! run_llm prompts/docs.md; then
        echo "❌ [smart-doc] Failed to run LLM" >&2
        exit 1
    fi
}

# Execute main function
main

# run_llm() {
#   # $1 prompt file, $2 output file, $3 label
#   local prompt_file="$1"; local out_file="$2"; local label="${3:-}"
#   case "$PROVIDER" in
#     codex)
#       if ! npx -y @openai/codex -v >/dev/null 2>&1; then
#         echo "❌ [$label] Codex CLI not available" >&2; return 1; fi
#       local extra_args=()
#       if [[ -n "$MODEL" ]]; then extra_args+=(--model "$MODEL"); fi
#       if [[ -n "$OPENAI_BASE_URL" ]]; then export OPENAI_BASE_URL; fi
#       if ! cat "$prompt_file" | npx -y @openai/codex "${extra_args[@]}" -- > "$out_file" 2>/dev/null; then
#         echo "❌ [$label] Codex generation failed" >&2; return 1; fi
#       ;;
#     openai)
#       # Use Codex CLI but allow overriding base URL for OpenAI-compatible hosts
#       if ! npx -y @openai/codex -v >/dev/null 2>&1; then
#         echo "❌ [$label] Codex CLI not available" >&2; return 1; fi
#       local extra_args=(--model "$MODEL")
#       if [[ -n "$OPENAI_BASE_URL" ]]; then export OPENAI_BASE_URL; fi
#       if ! cat "$prompt_file" | npx -y @openai/codex "${extra_args[@]}" -- > "$out_file" 2>/dev/null; then
#         echo "❌ [$label] OpenAI-compatible generation failed" >&2; return 1; fi
#       ;;
#     ollama)
#       if ! command -v ollama >/dev/null 2>&1; then
#         echo "❌ [$label] ollama not available" >&2; return 1; fi
#       local ollama_model="${MODEL:-qwen2.5-coder}"
#       if ! ollama run "$ollama_model" < "$prompt_file" > "$out_file"; then
#         echo "❌ [$label] ollama generation failed (model=$ollama_model)" >&2; return 1; fi
#       ;;
#     *)
#       echo "❌ [$label] Unknown PROVIDER=$PROVIDER" >&2; return 1;;
#   esac
# }

# if [[ "${MINI_MODE}" != "on" ]]; then
#   echo "🔧 [std] MINI_MODE=off → modo estándar v1 (double-pass codex; log-only configurable)"
#   mkdir -p tmp
#   # Mejor diff: comparar contra merge-base con la rama objetivo
#   BASE=$(git merge-base "origin/${BRANCH}" HEAD 2>/dev/null || git merge-base "${BRANCH}" HEAD 2>/dev/null || echo HEAD^)
#   CHANGED_FILES=$(git diff --name-only "$BASE"..HEAD || true)
#   PATCH_UNI=$(git diff --unified=0 "$BASE"..HEAD || true)
#   printf "%s\n" "$CHANGED_FILES" > tmp/changed_files.txt
#   printf "%s\n" "$PATCH_UNI" > tmp/patch.diff
#   FILES_COUNT=$(printf "%s" "$CHANGED_FILES" | sed '/^$/d' | wc -l | tr -d ' ')
#   PATCH_BYTES=$(printf "%s" "$PATCH_UNI" | wc -c | tr -d ' ')
#   echo "🔎 [std] files=$FILES_COUNT, patch_bytes=$PATCH_BYTES"
#   # Ensamblar CONTEXT
#   SHORT_SHA=$(git rev-parse --short HEAD || echo unknown)
#   UTC_DATE=$(env TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)
#   {
#     echo "Commit: $SHORT_SHA"
#     echo "DateUTC: $UTC_DATE"
#     echo "Base: $BASE"
#     echo
#     echo "Changed files:"; printf "%s\n" "$CHANGED_FILES" | sed '/^$/d' || true
#     echo
#     echo "Unified diff:"; printf "%s\n" "$PATCH_UNI" || true
#   } > tmp/context.txt

#   # 1) LLM pass para Timeline
#   echo "📝 [std] LLM pass 1 (timeline) via $PROVIDER (model=$MODEL)"
#   export CONTEXT="$(cat tmp/context.txt)"
#   if ! run_llm prompts/timeline.md tmp/timeline.out "std/timeline"; then exit 1; fi

#   # 2) LLM pass para Docs
#   echo "📚 [std] LLM pass 2 (docs) via $PROVIDER (model=$MODEL)"
#   export CONTEXT="$(cat tmp/context.txt)"
#   if ! run_llm prompts/docs.md tmp/docs.out "std/docs"; then exit 1; fi

#   echo "🧾 [std] OUTPUT_MODE=$OUTPUT_MODE → sin PR en desarrollo"
#   # Previews en logs (solo si existen)
#   if [[ -f tmp/timeline.out ]]; then
#     echo "--- timeline.out (head) ---"; head -c 2000 tmp/timeline.out || true; echo; echo "---------------------------"; fi
#   if [[ -f tmp/docs.out ]]; then
#     echo "--- docs.out (head) ---"; head -c 2000 tmp/docs.out || true; echo; echo "-----------------------"; fi
#   exit 0
# fi

# NEW_ENTRY="No hubo actualizaciones materiales de documentación en este diff; verificación mínima del pipeline."

# # Append with spacing
# if [[ -f "$TIMELINE" && -s "$TIMELINE" ]]; then echo >> "$TIMELINE"; fi
# echo "$NEW_ENTRY" >> "$TIMELINE"
# echo >> "$TIMELINE"

# echo "🧪 [mini] Entrada añadida: $NEW_ENTRY"

# if [[ "$OUTPUT_MODE" == "log" ]]; then
#   echo "🧾 [mini] OUTPUT_MODE=log → no push/PR (solo registro)"
#   exit 0
# fi

# # Commit and push PR branch
# git config user.email "github-actions[bot]@users.noreply.github.com"
# git config user.name "github-actions[bot]"
# git add "$TIMELINE"
# if git diff --cached --quiet; then
#   echo "✅ [mini] Sin cambios que commitear"; exit 0; fi

# git commit -m "chore(docs): timeline health entry [mini]"
# BR_NAME="smart-doc/docs-update-$(date +%s)"
# echo "🚀 [mini] Push $BR_NAME"
# git push -u origin "HEAD:$BR_NAME"

# if command -v gh >/dev/null 2>&1; then
#   gh pr create --head "$BR_NAME" --base "$BRANCH" \
#     --title "Smart Doc: minimal timeline update" \
#     --body "Minimal inline entrypoint appended a health entry to SMART_TIMELINE.md."
# else
#   echo "::warning::gh no disponible; PR no creado"
# fi

# echo "✅ [mini] Done"
