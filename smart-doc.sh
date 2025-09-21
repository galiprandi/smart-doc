#!/usr/bin/env bash
set -euo pipefail

log() {
    echo -e " [smart-doc] $1"
}

# Function to setup inputs
setup_inputs() {
    OPENAI_API_KEY="${OPENAI_API_KEY}"
    MODEL="${MODEL:-gpt-5-nano}"

    # Verify API key is set
    if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "sk-your-openai-key" ]; then
        log "❌ API key is not properly set"
        exit 1
    else
        log "✅ API key is configured"
    fi

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

# Function to log docs folder contents
log_docs_folder() {
    if [ -d "docs" ]; then
        log "📁 Docs folder contents:"
        find docs -type f -print | while read -r file; do
            log "  - $file"
        done
    else
        log "📁 No docs folder found"
    fi
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

    # Log docs folder contents
    log_docs_folder
}

# Execute main function
main
