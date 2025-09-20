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
  echo "🔧 [std] MINI_MODE=off → modo estándar v0 (solo logs)"
  mkdir -p tmp
  # Recolectar diff simple HEAD^..HEAD
  CHANGED_FILES=$(git diff --name-only HEAD^..HEAD || true)
  PATCH_UNI=$(git diff --unified=0 HEAD^..HEAD || true)
  printf "%s\n" "$CHANGED_FILES" > tmp/changed_files.txt
  printf "%s\n" "$PATCH_UNI" > tmp/patch.diff
  FILES_COUNT=$(printf "%s" "$CHANGED_FILES" | sed '/^$/d' | wc -l | tr -d ' ')
  PATCH_BYTES=$(printf "%s" "$PATCH_UNI" | wc -c | tr -d ' ')
  echo "🔎 [std] files=$FILES_COUNT, patch_bytes=$PATCH_BYTES"
  if [[ $FILES_COUNT -gt 0 ]]; then
    echo "✍️  [std] Generando docs/_changes.md (v1 mínimo)"
    mkdir -p docs
    SHORT_SHA=$(git rev-parse --short HEAD || echo unknown)
    UTC_DATE=$(env TZ=UTC date +%Y-%m-%dT%H:%M:%SZ)
    {
      echo "# Recent Changes"
      echo
      echo "- Date (UTC): $UTC_DATE"
      echo "- Commit: $SHORT_SHA"
      echo
      echo "## Changed Files"
      echo "$CHANGED_FILES" | sed '/^$/d' | sed 's/^/- /'
      echo
    } > docs/_changes.md
    echo "✅ [std] docs/_changes.md actualizado"
  else
    echo "ℹ️  [std] Sin archivos cambiados → no se escribe docs/_changes.md"
  fi
  if [[ "$OUTPUT_MODE" == "log" ]]; then
    echo "🧾 [std] OUTPUT_MODE=log → no push/PR (solo registro)"
    exit 0
  fi
  # OUTPUT_MODE=pr → commit y (futuro) PR
  git config user.email "github-actions[bot]@users.noreply.github.com"
  git config user.name "github-actions[bot]"
  git add docs/_changes.md || true
  if git diff --cached --quiet; then
    echo "ℹ️  [std] No hay cambios que publicar"; exit 0; fi
  git commit -m "docs: update _changes.md (standard v1)"
  BR_NAME="smart-doc/docs-update-$(date +%s)"
  echo "🚀 [std] Push $BR_NAME"
  git push -u origin "HEAD:$BR_NAME"
  if command -v gh >/dev/null 2>&1; then
    gh pr create --head "$BR_NAME" --base "$BRANCH" \
      --title "Smart Doc: update docs/_changes.md (std v1)" \
      --body "Standard v1 wrote docs/_changes.md from HEAD^..HEAD diff."
  else
    echo "::warning::gh no disponible; PR no creado"
  fi
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
