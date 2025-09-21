# Architecture

Last updated: 2025-09-21T05:29:20Z

Overview
- Smart Doc is a GitHub Action (composite) that generates repository documentation from code changes using an LLM CLI (Codex). The repository contains a minimal fallback `smart-doc.sh` entrypoint.

Runtime flow (minimal mode)

```mermaid
flowchart LR
  A["GitHub Action (composite)"] --> B["Entrypoint: smart-doc.sh"]
  B --> C["Validator / setup inputs"]
  C --> D["LLM CLI install (codex)"]
  D --> E["Run LLM with prompts/docs.md"]
  E --> F["Write/Update docs/ files"]
  F --> G["(Optional) publish PR via gh"]
```

Notes
- The repo also contains a fuller pipeline described in `AGENTS.md` (validator → diff-detector → prompt-builder → doc-updater → publisher). `smart-doc.sh` currently implements a minimal orchestrator that exercises LLM invocation and logs docs output.

