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

echo "Scaffolding $SERVICE..."

# Create directory structure
mkdir -p "$DEST"/.github/workflows
mkdir -p "$DEST"/.github/PULL_REQUEST_TEMPLATE
mkdir -p "$DEST"/.claude/rules
mkdir -p "$DEST"/src/"$SERVICE"
mkdir -p "$DEST"/tests/unit
mkdir -p "$DEST"/tests/integration

# Copy GitHub templates
cp templates/.github/workflows/ci.yml     "$DEST"/.github/workflows/ci.yml
cp templates/.github/workflows/deploy.yml "$DEST"/.github/workflows/deploy.yml
cp templates/.github/CODEOWNERS           "$DEST"/.github/CODEOWNERS
cp templates/.github/PULL_REQUEST_TEMPLATE/default.md "$DEST"/.github/PULL_REQUEST_TEMPLATE/default.md

# Copy Claude Code templates
cp templates/.claude/settings.json        "$DEST"/.claude/settings.json

# Copy project files
cp templates/tox.ini                      "$DEST"/tox.ini
cp templates/pyproject.toml               "$DEST"/pyproject.toml
cp templates/.gitignore                   "$DEST"/.gitignore
cp templates/CLAUDE.md                    "$DEST"/CLAUDE.md
cp templates/CLAUDE_SESSION.md            "$DEST"/CLAUDE_SESSION.md

# Update service-name in workflow files
sed -i "s/gooclaim-gateway/$SERVICE/g" "$DEST"/.github/workflows/ci.yml
sed -i "s/gooclaim-gateway/$SERVICE/g" "$DEST"/.github/workflows/deploy.yml

echo ""
echo "Done. $SERVICE scaffolded at $DEST"
echo ""
echo "Next steps:"
echo "  1. Copy the relevant .claude/rules/l{n}-{layer}.md into $DEST/.claude/rules/"
echo "  2. Update $DEST/CLAUDE.md with layer-specific context"
echo "  3. cd $DEST"
echo "  4. git init"
echo "  5. git remote add origin https://github.com/gooclaim-claimos/$SERVICE.git"
echo "  6. git checkout -b main && git add . && git commit -m 'chore: initial project setup'"
echo "  7. git push -u origin main"
echo "  8. git checkout -b develop && git push -u origin develop"
echo "  9. Set branch protection rules and environments on GitHub."
