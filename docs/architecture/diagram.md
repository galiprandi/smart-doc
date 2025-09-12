Mermaid Diagram

```mermaid
flowchart TD
    GH[GitHub Action Runtime]
    EP[entrypoint.sh]
    PROMPT[Build Prompt + Diffs]
    CODEBIN{Codex Binary Available?}
    CODE[code exec --sandbox workspace-write]
    CODEX[codex exec --sandbox workspace-write]
    NPX[npx -y @openai/codex exec --sandbox workspace-write]
    DOCS[Write docs under docs/]
    GITADD[(git add)]
    GITCOMMIT[(git commit)]
    BRANCH[(git switch -c update-branch)]
    PR[gh pr create]
    AUTOMERGE[gh pr merge --auto --squash]

    GH --> EP --> PROMPT --> CODEBIN
    CODEBIN -->|VSCode code| CODE --> DOCS
    CODEBIN -->|codex| CODEX --> DOCS
    CODEBIN -->|fallback| NPX --> DOCS
    DOCS --> GITADD --> GITCOMMIT --> BRANCH --> PR --> AUTOMERGE

    note right of EP
      Exports:
      - CODEX_SANDBOX=workspace-write
      - CODEX_REASONING_EFFORT=medium
      Removed:
      - CODEX_APPROVAL / --approval flag
    end note

    note left of GH
      Permissions required:
      - contents: write
      - pull-requests: write
    end note
```
