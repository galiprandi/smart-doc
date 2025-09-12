[![Smart Doc](https://github.com/galiprandi/smart-doc/actions/workflows/smart-doc.yml/badge.svg?branch=main)](https://github.com/galiprandi/smart-doc/actions/workflows/smart-doc.yml)

# Smart Doc — Living documentation for your repository

Bold, automated, and safe: the GitHub Action that auto‑documents your repo from diffs — incrementally, stack‑aware, and PR‑first.

Smart Doc converts each merge into precise, change‑only docs under `docs/`, creates or updates architecture and module pages when relevant, and opens a pull request for you. Protected branches stay protected; your docs stay fresh.

Benefits
- Auto‑documentation from diffs: change‑only updates under `docs/` (no wholesale rewrites).
- Project‑type aware: suggests and maintains an ideal docs structure (backend, frontend, library, monorepo, infra) and diagrams when they add value.
- Opportunistic verification: cross‑checks against your codebase (scripts, endpoints, env vars) to fix obvious inconsistencies.
- Auto‑PR to your target branch (ideal para protected branches).
- Works with any stack. Built for OpenAI; adaptable a otros proveedores.

Why Smart Doc
- Reduce documentation debt and stale READMEs/diagrams.
- Faster onboarding: “what changed” en minutos.
- Solo toca lo relevante al cambio; escala a monorepos.

How it works (at a glance)
- Detect diffs for the current run.
- Generate concise docs under `docs/` (English, change‑only) y opcional `SMART_TIMELINE.md`.
- Crear/actualizar una rama `smart-doc/docs-update-<sha>` y abrir un PR. Puede encolar auto‑merge o fusionar cuando sea seguro.

Requirements
- A GitHub repository con GitHub Actions habilitado.
- Un secreto: `SMART_DOC_API_TOKEN` (exportado como `OPENAI_API_KEY`).
- Permisos del job para PRs con `gh`:
  - `permissions.contents: write`
  - `permissions.pull-requests: write`
- Opcional: `GH_TOKEN` (PAT) si tu política limita `GITHUB_TOKEN`.

Quick start (minimal example)
```yaml
name: Smart Doc
on:
  push:
    branches: [ main ]
    paths-ignore:
      - 'docs/**'
      - 'SMART_TIMELINE.md'
  pull_request:
    branches: [ main ]

concurrency:
  group: smart-doc-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  update-docs:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Smart Doc
        uses: galiprandi/smart-doc@v1
        with:
          smart_doc_api_token: ${{ secrets.SMART_DOC_API_TOKEN }}
          branch: main
          docs_folder: docs
          generate_history: 'true'
```

More recipes and alternatives
- Triggers (GitFlow, release/*, PR‑only), monorepo `paths`, PAT vs `GITHUB_TOKEN`, merge modes y troubleshooting están en [`USAGE.md`](./USAGE.md).

Model compatibility
- OpenAI (Codex/GPT‑5): first‑class.
- Qwen / Qwen‑Code: configurable.

FAQ (short)
- Overwrites everything? No. Solo lo relacionado al diff actual.
- Diagramas? Sí, Mermaid cuando aporta valor.
- ¿Corre en PRs? Sí; sin pushes. En `main` abre PR y puede auto‑mergear.

License
MIT
