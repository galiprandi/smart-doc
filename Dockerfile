FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_OPTIONS=--max-old-space-size=2048

# Base tools
RUN apt-get update && apt-get install -y \
  curl ca-certificates gnupg git bash coreutils findutils \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (required by @openai/codex >=0.39)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get update \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Codex CLI globally (fallback to npx is still supported by scripts)
RUN npm install -g @openai/codex || true

# Copy repo
COPY . /app

# Default docs-out location inside container
ENV OPENAI_MODEL=gpt-5-nano \
    CODEX_MODEL=gpt-5-nano

# Usage:
#   docker build -t smart-doc-dev .
#   docker run --rm -e OPENAI_API_KEY=sk-... -v "$PWD":/app smart-doc-dev \
#     bash scripts/dev-run-docs.sh --prompt prompts/default.md --docs-out docs-out --clean

CMD ["bash","-lc","bash scripts/dev-run-docs.sh --prompt prompts/default.md --docs-out docs-out --clean"]
