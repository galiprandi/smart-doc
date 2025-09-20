#!/usr/bin/env bash
set -euo pipefail

echo "✳️  [mini] Minimal Smart Doc entrypoint"

# Inputs
BRANCH="${INPUT_BRANCH:-main}"
MODEL="${INPUT_MODEL:-gpt-5-nano}"
OPENAI_API_KEY="${INPUT_SMART_DOC_API_TOKEN:-${OPENAI_API_KEY:-}}"

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "::error::OPENAI_API_KEY / INPUT_SMART_DOC_API_TOKEN requerido"; exit 1
fi

# Ensure Codex CLI
if command -v codex >/dev/null 2>&1; then CODEX_BIN=(codex); 
elif command -v code >/dev/null 2>&1; then CODEX_BIN=(code);
elif command -v npx >/dev/null 2>&1; then CODEX_BIN=(npx -y @openai/codex);
else echo "::error::Codex CLI no disponible"; exit 1; fi

export OPENAI_API_KEY

TIMELINE="SMART_TIMELINE.md"
TMP_DIR=tmp; mkdir -p "$TMP_DIR"

read -r -d '' PROMPT << 'EOP'
Eres Smart Doc. Escribe únicamente una línea que sea la nueva entrada para SMART_TIMELINE.md (append-only). Reglas: Español; una sola línea; separar entradas con exactamente una línea en blanco; el archivo debe terminar con salto de línea. No modifiques otros archivos. Texto recomendado si no hay nada más que documentar: "No hubo actualizaciones materiales de documentación en este diff; verificación mínima del pipeline."
EOP

CONTEXT=""
if [[ -f "$TIMELINE" ]]; then
  CONT=$(sed -n '1,80p' "$TIMELINE" || true)
  CONTEXT="Contexto actual de SMART_TIMELINE.md (parcial):\n---8<---\n$CONT\n---8<---"
fi
printf "%s\n\n%s\n" "$PROMPT" "$CONTEXT" > "$TMP_DIR/prompt.txt"

echo "✍️  [mini] Llamando Codex ($MODEL)"
set +e
"${CODEX_BIN[@]}" --model "$MODEL" --input-file "$TMP_DIR/prompt.txt" --output-file "$TMP_DIR/response.txt"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then echo "::warning::Codex devolvió $RC"; fi

NEW_ENTRY="No hubo actualizaciones materiales de documentación en este diff; verificación mínima del pipeline."
if [[ -s "$TMP_DIR/response.txt" ]]; then
  LINE=$(sed -n '/./{p;q;}' "$TMP_DIR/response.txt" | tr -d '\r')
  [[ -n "$LINE" ]] && NEW_ENTRY="$LINE"
fi

# Append with spacing
if [[ -f "$TIMELINE" && -s "$TIMELINE" ]]; then echo >> "$TIMELINE"; fi
echo "$NEW_ENTRY" >> "$TIMELINE"
echo >> "$TIMELINE"

echo "🧪 [mini] Entrada añadida: $NEW_ENTRY"

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
