#!/bin/bash
# scripts/deploy.sh
#
# ⚠️  DEPRECATED (2026-05-17, S4) — DO NOT USE
#
# This script assumes:
#   • Registry = ghcr.io/gooclaim/* (we use gooclaimacrdev.azurecr.io)
#   • Namespace = gooclaim-${env}  (we use single "gooclaim" namespace)
#   • Services = L0/L1/L2/L3/L5/L6 names (renamed to gooclaim-* slugs)
#   • Deploy method = kubectl set image (causes helm field-manager conflicts)
#
# Replaced by `.github/workflows/_reusable-deploy.yml` (helm-based, ACR-based,
# OIDC-authenticated). See that file + templates/.github/workflows/deploy.yml
# for the current pattern.
#
# Kept for historical reference only.

set -euo pipefail
echo "❌ This script is deprecated. Use the GitHub Actions Deploy workflow instead."
echo "   See gooclaim-infra/.github/workflows/_reusable-deploy.yml"
exit 1

ENV=$1
SHA=$2

if [[ -z "$ENV" || -z "$SHA" ]]; then
  echo "Usage: deploy.sh <env> <sha>"
  exit 1
fi

VALID_ENVS=("dev" "sdx" "nprd" "prod")
if [[ ! " ${VALID_ENVS[*]} " =~ " ${ENV} " ]]; then
  echo "Invalid env: $ENV. Must be one of: ${VALID_ENVS[*]}"
  exit 1
fi

echo "Deploying SHA=$SHA to ENV=$ENV"

# Write kubeconfig from secret
mkdir -p ~/.kube
echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config
chmod 600 ~/.kube/config

NAMESPACE="gooclaim-$ENV"
REGISTRY="ghcr.io/gooclaim"

SERVICES=(
  "l0-channel-gateway"
  "l1-workflow-engine"
  "l2-truth-layer"
  "l3-knowledge-layer"
  "l5-outbound-engine"
  "l6-policy-gate"
)

for SERVICE in "${SERVICES[@]}"; do
  IMAGE="$REGISTRY/$SERVICE:$SHA"
  echo "Updating $SERVICE → $IMAGE"

  kubectl set image deployment/$SERVICE \
    $SERVICE=$IMAGE \
    -n $NAMESPACE

  kubectl rollout status deployment/$SERVICE \
    -n $NAMESPACE \
    --timeout=120s

  echo "$SERVICE rollout complete"
done

echo "All services deployed to $ENV successfully"
echo "SHA: $SHA"
echo "Namespace: $NAMESPACE"
