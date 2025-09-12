Mermaid Diagram

```mermaid
flowchart TD
  A[GitHub Action: Smart Doc] --> B[entrypoint.sh]
  B --> C[Compute changed files + diffs]
  C --> D[Generate docs via OpenAI]
  D --> E[Write to docs/ (+timeline)]
  E --> F[Create branch smart-doc/docs-update-<sha>]
  F --> G[Push branch]

  subgraph GH[GitHub operations]
    H[Set GH_TOKEN from GH_TOKEN||GITHUB_TOKEN]
    I[Resolve REPO_SLUG]
    J[gh pr create --repo <slug>]
    K{PR created?}
    L[gh pr list --repo <slug>]
    M[gh pr merge --repo <slug> --auto --squash]
  end

  G --> H --> I --> J --> K
  K -- no --> L --> M
  K -- yes --> M
```

