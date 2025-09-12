Mermaid Diagram

```mermaid
flowchart TD
  A[GitHub Action: Smart Doc] --> B[entrypoint.sh]
  B --> C[Compute changed files + diffs via gh]
  C --> D[Generate docs via OpenAI]
  D --> E[Write to docs/ (+timeline)]
  E --> F[Create branch smart-doc/docs-update-<sha>]
  F --> G[Push branch]

  subgraph GH[GitHub operations]
    H[Auth: gh with GITHUB_TOKEN or GH_TOKEN]
    I[Resolve REPO_SLUG]
    J{PR exists?}
    K[gh pr create --repo <slug>]
    L[gh pr list --repo <slug>]
    M[Merge orchestration]
  end

  G --> H --> I --> J
  J -- no --> K --> M
  J -- yes --> L --> M

  subgraph Merge
    M1[auto: gh pr merge --auto --squash]
    M2[immediate: wait -> squash]
    M3[off: leave PR open]
  end

  M --> M1
  M --> M2
  M --> M3
```

