Mermaid Diagram

```mermaid
flowchart TD
  A[GitHub Action: Smart Doc] --> B[entrypoint.sh]
  B --> C[Compute changed files + diffs]
  C --> D[Generate docs via OpenAI]
  D --> E[Write to docs/ (+timeline)]
  E --> F[Fetch/prune origin]
  F --> G{origin/update-branch exists?}
  G -- yes --> B1[checkout -B from origin]
  G -- no --> B2[switch -c new branch]
  B1 --> B3[Push]
  B2 --> B3[Push]
  B3 -- fails --> B4[Push with --force-with-lease]

  subgraph GH[GitHub operations]
    GH1[Set GH_TOKEN from GH_TOKEN||GITHUB_TOKEN]
    GH2[Resolve REPO_SLUG]
    GH3[gh pr create --repo <slug>]
    GH4{PR created?}
    GH5[gh pr list --repo <slug>]
    GH6[gh pr merge --repo <slug> --auto --squash]
  end

  B3 --> GH1 --> GH2 --> GH3 --> GH4
  GH4 -- no --> GH5 --> GH6
  GH4 -- yes --> GH6
```
