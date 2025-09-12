Mermaid Diagram

```mermaid
flowchart TD
    GH[GitHub Actions Runtime]
    SELF{Self-commit?}
    EP[entrypoint.sh]
    PROMPT[Build Prompt + Diffs]
    CODEBIN{Codex Binary Available?}
    CODE[code exec --sandbox workspace-write]
    CODEX[codex exec --sandbox workspace-write]
    NPX[npx -y @openai/codex exec --sandbox workspace-write]
    DOCS[Write docs under docs/]
    GIT[(git add/commit/push on push events)]
    ARTIFACT[[Upload docs preview (PR)]]

    GH --> SELF
    SELF -- yes -->|skip generation| ARTIFACT
    SELF -- no --> EP --> PROMPT --> CODEBIN
    CODEBIN -->|VSCode code| CODE --> DOCS
    CODEBIN -->|codex| CODEX --> DOCS
    CODEBIN -->|fallback| NPX --> DOCS
    DOCS --> GIT
    DOCS -. PR only .-> ARTIFACT

    note right of EP
      Exports (examples):
      - CODEX_SANDBOX=workspace-write
      - CODEX_REASONING_EFFORT=medium
    end note

    note left of GH
      CI specifics in this repo:
      - Self-commit guard on push
      - PR preview via upload-artifact
    end note
```
