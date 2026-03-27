#!/bin/bash
# scripts/deploy.sh
# Usage: bash scripts/deploy.sh <env> <sha>
# Called by GitHub Actions deploy jobs
# Requires KUBE_CONFIG env var to be set

set -euo pipefail

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
