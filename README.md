# gooclaim-infra/templates/
# Yahan se copy karo jab naya service repo banao
# Sirf service-name update karna hai baaki sab same rahega

## Files to copy to every new service repo

```
templates/
├── workflows/
│   ├── ci.yml           → .github/workflows/ci.yml
│   └── deploy.yml       → .github/workflows/deploy.yml
├── tox.ini              → tox.ini
├── pyproject.toml       → pyproject.toml
├── Dockerfile           → Dockerfile
├── CLAUDE_SESSION.md    → CLAUDE_SESSION.md
└── pull_request_template.md → .github/PULL_REQUEST_TEMPLATE/pull_request_template.md
```

## One command setup (jab repo clone karo)

```bash
# Naya service repo setup karne ka script
# Usage: bash setup-service.sh gooclaim-gateway
# Run karo: gooclaim-infra root se

SERVICE=$1

if [ -z "$SERVICE" ]; then
  echo "Usage: bash setup-service.sh <service-name>"
  echo "Example: bash setup-service.sh gooclaim-gateway"
  exit 1
fi

echo "Setting up $SERVICE..."

# Directories
mkdir -p ../$SERVICE/.github/workflows
mkdir -p ../$SERVICE/.github/PULL_REQUEST_TEMPLATE
mkdir -p ../$SERVICE/src/$SERVICE
mkdir -p ../$SERVICE/tests/unit
mkdir -p ../$SERVICE/tests/integration

# Copy templates
cp templates/workflows/ci.yml ../$SERVICE/.github/workflows/ci.yml
cp templates/workflows/deploy.yml ../$SERVICE/.github/workflows/deploy.yml
cp templates/tox.ini ../$SERVICE/tox.ini
cp templates/pyproject.toml ../$SERVICE/pyproject.toml
cp templates/Dockerfile ../$SERVICE/Dockerfile
cp templates/CLAUDE_SESSION.md ../$SERVICE/CLAUDE_SESSION.md
cp templates/pull_request_template.md ../$SERVICE/.github/PULL_REQUEST_TEMPLATE/pull_request_template.md

# Update service-name in workflows
sed -i "s/gooclaim-gateway/$SERVICE/g" ../$SERVICE/.github/workflows/ci.yml
sed -i "s/gooclaim-gateway/$SERVICE/g" ../$SERVICE/.github/workflows/deploy.yml

echo "Done. Now:"
echo "  1. cd ../$SERVICE"
echo "  2. Update CLAUDE.md with layer-specific rules"
echo "  3. git init && git remote add origin https://github.com/gooclaim/$SERVICE"
echo "  4. git checkout -b develop"
echo "  5. git push -u origin develop"
```
