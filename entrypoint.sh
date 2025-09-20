#!/usr/bin/env bash
set -euo pipefail

echo "✳️  [smart-doc] Entrypoint"

# Inputs
BRANCH="${INPUT_BRANCH:-main}"
MINI_MODE="${INPUT_MINI_MODE:-${MINI_MODE:-on}}"  # on|off
OUTPUT_MODE="${INPUT_OUTPUT_MODE:-${OUTPUT_MODE:-pr}}"  # pr|log
OPENAI_API_KEY="${INPUT_SMART_DOC_API_TOKEN:-${OPENAI_API_KEY:-}}"

TIMELINE="SMART_TIMELINE.md"
TMP_DIR=tmp; mkdir -p "$TMP_DIR"

if [[ "${MINI_MODE}" != "on" ]]; then
  echo "🔧 [std] MINI_MODE=off → modo estándar v1 (double-pass codex; log-only configurable)"
  mkdir -p tmp
  # Mejor diff: comparar contra merge-base con la rama objetivo
  BASE=$(git merge-base "origin/${BRANCH}" HEAD 2>/dev/null || git merge-base "${BRANCH}" HEAD 2>/dev/null || echo HEAD^)
  CHANGED_FILES=$(git diff --name-only "$BASE"..HEAD || true)
  PATCH_UNI=$(git diff --unified=0 "$BASE"..HEAD || true)
  printf "%s\n" "$CHANGED_FILES" > tmp/changed_files.txt
  printf "%s\n" "$PATCH_UNI" > tmp/patch.diff
  FILES_COUNT=$(printf "%s" "$CHANGED_FILES" | sed '/^$/d' | wc -l | tr -d ' ')
  PATCH_BYTES=$(printf "%s" "$PATCH_UNI" | wc -c | tr -d ' ')
  echo "🔎 [std] files=$FILES_COUNT, patch_bytes=$PATCH_BYTES"
  # Ensamblar CONTEXT
  SHORT_SHA=$(git rev-parse --short HEAD || echo unknown)
  UTC_DATE=$(env TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)
  {
    echo "Commit: $SHORT_SHA"
    echo "DateUTC: $UTC_DATE"
    echo "Base: $BASE"
    echo
    echo "Changed files:"; printf "%s\n" "$CHANGED_FILES" | sed '/^$/d' || true
    echo
    echo "Unified diff:"; printf "%s\n" "$PATCH_UNI" || true
  } > tmp/context.txt

  # 1) Ejecutar Codex para Timeline
  if command -v code >/dev/null 2>&1 || command -v codex >/dev/null 2>&1 || npx -y @openai/codex -v >/dev/null 2>&1; then
    echo "📝 [std] Codex pass 1 (timeline)"
    export CONTEXT="$(cat tmp/context.txt)"
    : ${CODEX_BIN:=$(command -v code || command -v codex || echo "npx -y @openai/codex")}
    # Pasar archivo como prompt; redirigir salida a tmp
    if [[ "$CODEX_BIN" == npx* ]]; then
      $CODEX_BIN -- "$(cat prompts/timeline.md)" > tmp/timeline.out 2>/dev/null || echo "::warning::Codex timeline falló; continuando"
    else
      $CODEX_BIN "$(cat prompts/timeline.md)" > tmp/timeline.out 2>/dev/null || echo "::warning::Codex timeline falló; continuando"
    fi
  else
    echo "::warning::Codex CLI no disponible; saltando pass de timeline"
  fi

  # 2) Ejecutar Codex para Docs
  if command -v code >/dev/null 2>&1 || command -v codex >/dev/null 2>&1 || npx -y @openai/codex -v >/dev/null 2>&1; then
    echo "📚 [std] Codex pass 2 (docs)"
    export CONTEXT="$(cat tmp/context.txt)"
    : ${CODEX_BIN:=$(command -v code || command -v codex || echo "npx -y @openai/codex")}
    if [[ "$CODEX_BIN" == npx* ]]; then
      $CODEX_BIN -- "$(cat prompts/docs.md)" > tmp/docs.out 2>/dev/null || echo "::warning::Codex docs falló; continuando"
    else
      $CODEX_BIN "$(cat prompts/docs.md)" > tmp/docs.out 2>/dev/null || echo "::warning::Codex docs falló; continuando"
    fi
  else
    echo "::warning::Codex CLI no disponible; saltando pass de docs"
  fi

  echo "🧾 [std] OUTPUT_MODE=$OUTPUT_MODE → sin PR en desarrollo"
  # Previews en logs (solo si existen)
  if [[ -f tmp/timeline.out ]]; then
    echo "--- timeline.out (head) ---"; head -c 2000 tmp/timeline.out || true; echo; echo "---------------------------"; fi
  if [[ -f tmp/docs.out ]]; then
    echo "--- docs.out (head) ---"; head -c 2000 tmp/docs.out || true; echo; echo "-----------------------"; fi
  exit 0
fi

NEW_ENTRY="No hubo actualizaciones materiales de documentación en este diff; verificación mínima del pipeline."

# Append with spacing
if [[ -f "$TIMELINE" && -s "$TIMELINE" ]]; then echo >> "$TIMELINE"; fi
echo "$NEW_ENTRY" >> "$TIMELINE"
echo >> "$TIMELINE"

echo "🧪 [mini] Entrada añadida: $NEW_ENTRY"

if [[ "$OUTPUT_MODE" == "log" ]]; then
  echo "🧾 [mini] OUTPUT_MODE=log → no push/PR (solo registro)"
  exit 0
fi

# Commit and push PR branch
git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"
git add "$TIMELINE"
if git diff --cached --quiet; then
  echo "✅ [mini] Sin cambios que commitear"; exit 0; fi

git commit -m "chore(docs): timeline health entry [mini]"
BR_NAME="smart-doc/docs-update-$(date +%s)"
echo "🚀 [mini] Push $BR_NAME"
git push -u origin "HEAD:$BR_NAME"

if command -v gh >/dev/null 2>&1; then
  gh pr create --head "$BR_NAME" --base "$BRANCH" \
    --title "Smart Doc: minimal timeline update" \
    --body "Minimal inline entrypoint appended a health entry to SMART_TIMELINE.md."
else
  echo "::warning::gh no disponible; PR no creado"
fi

echo "✅ [mini] Done"
