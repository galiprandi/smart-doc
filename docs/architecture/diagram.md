```mermaid
flowchart TD
  A[Commit Diff] --> B[Diff Detector]
  B --> C[Temporary outputs: changed_files.txt, patch.diff]
  C --> D[Prompt Builder]
  D --> E[Doc Updater (Codex CLI)]
  E --> F[Docs updated in docs/]
  F --> G[Publisher (PR)]
```

Notes:
- This diagram reflects the current flow touched by the diff and doc-updater changes.

