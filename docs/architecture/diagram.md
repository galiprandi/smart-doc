Architecture Diagram

```mermaid
flowchart TD
  A[GitHub Actions Runner] --> B[Smart Doc Action]\n
  subgraph B[Composite Action]
    B1[entrypoint.sh]\n
    B1 --> C[Collect changed files + diffs]
    B1 --> D[Build prompt]
    B1 --> E[Run Codex CLI]\n
    E --> F[Write docs to docs/] 
    E --> G[Update SMART_TIMELINE.md]
  end

  subgraph H[Auth & Tokens]
    T1[SMART_DOC_API_TOKEN -> OPENAI_API_KEY]
    T2[GITHUB_TOKEN (contents, PRs) or GH_TOKEN]
  end

  B1 -. uses .-> T1
  B1 -. uses .-> T2

  F --> I[Create branch smart-doc/docs-update-<sha>]
  I --> J[gh pr create]
  J --> K[PR opened to target branch]
```

Notes
- `gh` authenticates via `GITHUB_TOKEN` (preferred) or `GH_TOKEN` (from a PAT) to open the PR.
- The action does not push directly to protected branches.

