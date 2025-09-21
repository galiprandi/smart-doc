# Repository Guidelines

## Project Structure & Module Organization
- Code and action entry: `smart-doc.sh`
- Documentation outputs: `docs/` (e.g., `docs/README.md`, `docs/architecture.md`)
- Prompts/templates: `prompts/`
- CI config: `.github/` (workflows, permissions)
- Repo docs: `README.md`, `USAGE.md`, `CONTRIBUTING.md`
- Env files: `.env`, `.env.example` (API keys; never commit secrets)

## Build, Test, and Development Commands
- Setup env (local): `cp .env.example .env && $EDITOR .env`
- Run generator locally: `bash smart-doc.sh`
  - Installs Codex CLI if missing, builds prompt from `prompts/`, writes docs under `docs/`, logs to `tmp/`.
- Check outputs: `git status --porcelain docs SMART_TIMELINE.md && ls -la docs`
- CI entry: GitHub Actions workflow at `.github/workflows/smart-doc.yml` runs on PRs and pushes.

## Coding Style & Naming Conventions
- Shell (Bash): strict mode (`set -euo pipefail`), small functions, clear logs.
- Indentation: 2 spaces; no tabs.
- Filenames: kebab-case for scripts (`*.sh`), nouns/verbs over abbreviations.
- Branches created by CI: `smart-doc/docs-update-<short-sha>`.
- Keep logs concise; prefer emoji markers (e.g., ✳️, 📚, ✅) consistent with existing scripts.

## Testing Guidelines
- No unit test suite today; validate behavior by running `bash smart-doc.sh` and reviewing diffs in `docs/`.
- Ensure `OPENAI_API_KEY` is set (via `.env` or environment) and that runs are deterministic for a given diff.
- When changing prompt text, verify `tmp/` artifacts (if present) and confirm only relevant docs update.

## Commit & Pull Request Guidelines
- Commits: `type(scope): subject` when useful. Examples: `fix(generator): handle empty diff`, `docs: clarify usage`, `ci: adjust permissions`.
- PRs: include a clear description, link related issues, and add before/after context or screenshots for `docs/` updates.
- Keep PRs focused and small; avoid mixing refactors with behavior changes.

## Security & Configuration Tips
- Secrets: never commit `.env`. In CI, use `secrets.OPENAI_API_KEY` (or `SMART_DOC_API_TOKEN`) with least privileges.
- Permissions: workflows require `contents: write` and `pull-requests: write` for publishing doc PRs.

## Communication Style (Agent) ✨
- Always reply brief and concise; prioritize clarity.
- Place emojis on the left to lead sections/steps (e.g., ✅ Result, ⚙️ Setup, 🧪 Test, 🚀 Publish).
- Prefer short headers and bullet points; avoid verbose paragraphs.
- Include inline commands/paths in backticks and keep outputs minimal.
- Example:
  - ✅ Listo: docs actualizados en `docs/`
  - 🧪 Prueba: ejecuta `bash smart-doc.sh`
