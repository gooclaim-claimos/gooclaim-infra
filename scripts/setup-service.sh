#!/bin/bash
# setup-service.sh
# Scaffolds a new Gooclaim service repo from templates.
# Usage: bash scripts/setup-service.sh <service-name>
# Example: bash scripts/setup-service.sh gooclaim-gateway
# Run from: gooclaim-infra root

set -e

SERVICE=$1

if [ -z "$SERVICE" ]; then
  echo "Error: service name required."
  echo "Usage: bash scripts/setup-service.sh <service-name>"
  echo "Example: bash scripts/setup-service.sh gooclaim-gateway"
  exit 1
fi

DEST="../$SERVICE"

if [ -d "$DEST" ]; then
  echo "Error: directory $DEST already exists."
  exit 1
fi

# Detect which layer rule to copy based on service name
case "$SERVICE" in
  *gateway*)  LAYER_RULE="l0-gateway.md" ;;
  *engine*)   LAYER_RULE="l1-workflow.md" ;;
  *truth*)    LAYER_RULE="l2-truth.md" ;;
  *knowledge*)LAYER_RULE="l3-knowledge.md" ;;
  *learning*) LAYER_RULE="l4-learning.md" ;;
  *outbound*) LAYER_RULE="l5-outbound.md" ;;
  *policy*)   LAYER_RULE="l6-policy.md" ;;
  *observe*)  LAYER_RULE="l7-observe.md" ;;
  *)          LAYER_RULE="" ;;
esac

echo "Scaffolding $SERVICE..."

# ─── Directory structure ──────────────────────────────────
mkdir -p "$DEST"/.github/workflows
mkdir -p "$DEST"/.github/PULL_REQUEST_TEMPLATE
mkdir -p "$DEST"/.claude/rules
mkdir -p "$DEST"/.claude/skills
mkdir -p "$DEST"/.claude/hooks
mkdir -p "$DEST"/src/"$SERVICE"/routes
mkdir -p "$DEST"/src/"$SERVICE"/services
mkdir -p "$DEST"/src/"$SERVICE"/models
mkdir -p "$DEST"/src/"$SERVICE"/connectors
mkdir -p "$DEST"/migrations
mkdir -p "$DEST"/tests/unit
mkdir -p "$DEST"/tests/integration
mkdir -p "$DEST"/badges

# ─── GitHub templates ─────────────────────────────────────
cp templates/.github/workflows/ci.yml                        "$DEST"/.github/workflows/ci.yml
cp templates/.github/workflows/deploy.yml                    "$DEST"/.github/workflows/deploy.yml
cp templates/.github/CODEOWNERS                              "$DEST"/.github/CODEOWNERS
cp templates/.github/PULL_REQUEST_TEMPLATE/default.md        "$DEST"/.github/PULL_REQUEST_TEMPLATE/default.md

# Update service-name in workflow files
sed -i "s/gooclaim-service/$SERVICE/g" "$DEST"/.github/workflows/ci.yml
sed -i "s/gooclaim-service/$SERVICE/g" "$DEST"/.github/workflows/deploy.yml

# ─── Claude Code setup ────────────────────────────────────
# settings.json (hooks config)
cat > "$DEST"/.claude/settings.json <<EOF
{
  "hooks": {
    "pre-tool-use": [
      {
        "matcher": "Write|Edit",
        "hooks": [".claude/hooks/check-no-secrets.sh"]
      }
    ]
  }
}
EOF

# Secret check hook
cp .claude/hooks/check-no-secrets.sh "$DEST"/.claude/hooks/check-no-secrets.sh
chmod +x "$DEST"/.claude/hooks/check-no-secrets.sh

# Layer-specific rule (auto-detected)
if [ -n "$LAYER_RULE" ]; then
  cp "templates/.claude/rules/$LAYER_RULE" "$DEST"/.claude/rules/"$LAYER_RULE"
fi

# Skills — all 4
cp templates/.claude/skills/docs.md         "$DEST"/.claude/skills/docs.md
cp templates/.claude/skills/new-adr.md      "$DEST"/.claude/skills/new-adr.md
cp templates/.claude/skills/session-end.md  "$DEST"/.claude/skills/session-end.md
cp templates/.claude/skills/test.md         "$DEST"/.claude/skills/test.md

# ─── Project files ────────────────────────────────────────
cp templates/tox.ini        "$DEST"/tox.ini
cp templates/pyproject.toml "$DEST"/pyproject.toml
cp templates/.gitignore     "$DEST"/.gitignore
cp templates/CLAUDE.md      "$DEST"/CLAUDE.md
cp templates/CLAUDE_SESSION.md "$DEST"/CLAUDE_SESSION.md
cp templates/Dockerfile     "$DEST"/Dockerfile

# ─── Source skeleton ──────────────────────────────────────
touch "$DEST"/src/"$SERVICE"/__init__.py
touch "$DEST"/src/"$SERVICE"/routes/__init__.py
touch "$DEST"/src/"$SERVICE"/services/__init__.py
touch "$DEST"/src/"$SERVICE"/models/__init__.py
touch "$DEST"/src/"$SERVICE"/connectors/__init__.py
touch "$DEST"/migrations/.gitkeep

cat > "$DEST"/src/"$SERVICE"/config.py <<EOF
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    env: str = "dev"
    log_level: str = "INFO"

    database_url: str
    redis_url: str = "redis://localhost:6379"

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
EOF

cat > "$DEST"/src/"$SERVICE"/main.py <<EOF
from fastapi import FastAPI

from .config import settings

app = FastAPI(title="$SERVICE", docs_url="/docs" if settings.env != "prod" else None)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "$SERVICE", "env": settings.env}
EOF

# ─── Test skeleton ────────────────────────────────────────
cat > "$DEST"/tests/conftest.py <<EOF
import pytest


# Add shared fixtures here
# Example:
# @pytest.fixture
# def db_session(): ...
EOF

touch "$DEST"/tests/unit/.gitkeep
touch "$DEST"/tests/integration/.gitkeep

# ─── Docker local dev ─────────────────────────────────────
cat > "$DEST"/docker-compose.yml <<EOF
# Local development only — not for production
version: "3.9"

services:
  app:
    build: .
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./src:/app/src   # hot reload in dev

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: gooclaim
      POSTGRES_PASSWORD: localpass
      POSTGRES_DB: gooclaim_dev
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "gooclaim"]
      interval: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
EOF

cat > "$DEST"/.dockerignore <<EOF
.git
.github
.claude
.tox
.venv
__pycache__
*.pyc
*.pyo
*.egg-info
htmlcov
coverage.xml
badges
.env
.env.*
tests
docs
*.md
EOF

# ─── README skeleton ──────────────────────────────────────
cat > "$DEST"/README.md <<EOF
# $SERVICE

> Part of [Gooclaim](https://github.com/gooclaim-claimos) — India's Claims OS

## What this service does

TODO: Add one-line description.

## Quick start

\`\`\`bash
pip install tox
tox -e test          # run tests
tox                  # lint + typecheck + security + test
\`\`\`

## Docs

See [docs/00-overview.md](docs/00-overview.md) — run \`/docs\` in Claude Code to generate full docs.

## CI status

![Coverage](badges/coverage.svg)
EOF

# ─── .env.example ─────────────────────────────────────────
cat > "$DEST"/.env.example <<EOF
# Copy to .env and fill in values
# Never commit .env — it's in .gitignore

ENV=dev
LOG_LEVEL=INFO

# Database
DATABASE_URL=postgresql://gooclaim:password@localhost:5432/gooclaim_dev

# Redis
REDIS_URL=redis://localhost:6379

# Add service-specific vars below
EOF

# ─── Done ─────────────────────────────────────────────────
echo ""
echo "✓ $SERVICE scaffolded at $DEST"
echo ""
echo "What was created:"
echo "  .github/workflows/ci.yml + deploy.yml  (caller files)"
echo "  .claude/hooks/check-no-secrets.sh      (secret blocker)"
if [ -n "$LAYER_RULE" ]; then
echo "  .claude/rules/$LAYER_RULE              (layer rules)"
fi
echo "  .claude/skills/                        (4 skills)"
echo "  src/$SERVICE/main.py                   (FastAPI skeleton)"
echo "  tests/conftest.py                      (pytest config)"
echo "  Dockerfile, tox.ini, pyproject.toml"
echo "  README.md, .env.example"
echo ""
echo "Next steps:"
echo "  1. Update CLAUDE.md with layer-specific context"
echo "  2. cd $DEST"
echo "  3. git init"
echo "  4. git remote add origin https://github.com/gooclaim-claimos/$SERVICE.git"
echo "  5. git checkout -b main"
echo "  6. git add . && git commit -m 'chore: initial project setup'"
echo "  7. git push -u origin main"
echo "  8. git checkout -b develop && git push -u origin develop"
echo "  9. Set branch protection + environments on GitHub"
