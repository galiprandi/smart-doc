- Título: Documentación inicial y scaffolding tras cambios en entrypoint.sh
- Fecha: 2025-09-12
- Alcance (Scope): Documentación de alto nivel, diagramas y módulos
- TL;DR: Se generan y actualizan archivos de documentación en docs/ para reflejar cambios en entrypoint.sh y aumentar la visibilidad de la arquitectura y módulos. Se dejan TODOs para completar detalles tras la revisión del diff.
---
- Title: Remove explicit Codex approval flag
- Date: 2025-09-12
- Scope: docs, entrypoint.sh
- TL;DR: Updated docs to reflect removal of `CODEX_APPROVAL` and `--approval` usage; Codex CLI now relies on its default approval behavior while retaining `workspace-write` sandbox and `medium` reasoning effort.
---
- Title: Reposition Smart Doc + update usage
- Date: 2025-09-12
- Scope: docs (README, stack, architecture), action.yml
- TL;DR: Updated documentation to reflect provider‑agnostic positioning (OpenAI first‑class, Qwen adaptable), clarified outputs (README, stack, architecture, modules), and aligned usage to `galiprandi/smart-doc@v1`.

## Clarify HISTORY.md formatting rules
- Date: 2025-09-12
- Scope: prompts, docs
- TL;DR: Documented strict HISTORY.md entry format and spacing; updated docs to reflect requirements.

## Chore: Trigger Smart Doc PR flow test
- Date: 2025-09-12
- Scope: README
- TL;DR: Added a no-op HTML comment to README to exercise PR flow; no functional changes.

## Document CI concurrency and flexible triggers
- Date: 2025-09-12
- Scope: docs (README, stack, architecture), workflows
- TL;DR: Added GitHub Actions `concurrency` example (cancel in-progress) and documented customizable triggers (main/develop/release/*/PRs); aligned examples with updated workflow.
