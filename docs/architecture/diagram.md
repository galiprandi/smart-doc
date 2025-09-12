```mermaid
flowchart TD
  GH[GitHub event (push/PR)] --> Diff[Compute changed files + unified diffs]
  Diff --> Prompt[Assemble prompt from template]
  Prompt --> CLI[Run Codex CLI]
  CLI --> Docs[Write docs/* under docs/]
  CLI --> Timeline{Generate SMART_TIMELINE.md?}
  Timeline -- yes --> ST[Append SMART_TIMELINE.md]
  Timeline -- no --> Skip[No timeline changes]
  Docs --> Branch[Create branch smart-doc/docs-update-<sha>]
  ST --> Branch
  Branch --> PR[Open PR; enable auto-merge (squash)]
```

