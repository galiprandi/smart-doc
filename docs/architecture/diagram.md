Mermaid Diagram

```mermaid
flowchart TD
  A[Push event on default branch] --> B[Compute changed files + diffs]
  B --> C[Generate docs under docs/]
  C --> D[Commit and create PR smart-doc/docs-update-<short-sha>]
  D --> E[Detect changed docs scope]
  E --> F[Extract ticket keys from commit msg + PR title]
  F --> G{Jira inputs provided?}
  G -- yes --> H[Enrich tickets via Jira REST]
  G -- no --> I[Use raw keys]
  H --> J[Build SMART_TIMELINE entry]
  I --> J[Build SMART_TIMELINE entry]
  J --> K[Append to SMART_TIMELINE.md and push]
  K --> L[Edit PR body with preview]
  L --> M[Attempt auto-merge (squash)]
```

