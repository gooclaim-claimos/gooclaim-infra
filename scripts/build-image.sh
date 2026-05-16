#!/bin/bash
# scripts/build-image.sh
# Usage:
#   bash scripts/build-image.sh <expected-service-name> [docker-build-args...]
#
# Asserts the current working directory's basename matches <expected-service-name>
# BEFORE invoking `docker build`. Closes PB-13 — protects against accidentally
# building gooclaim-engine while cwd is gooclaim-outbound (which has bitten us
# during the cloud-deploy days when 20+ service repos sit side-by-side).
#
# Examples:
#   cd ~/Gooclaom-ClaimOS/gooclaim-engine
#   bash ../scripts/build-image.sh gooclaim-engine -t ghcr.io/.../engine:v0.1
#
#   # Wrong cwd → exits 1 before docker is touched:
#   cd /tmp
#   bash ~/Gooclaom-ClaimOS/scripts/build-image.sh gooclaim-engine
#   # ❌ wrong cwd: expected 'gooclaim-engine', got 'tmp'
#   # → exit 1
#
# Why exists: rapid context-switching between repos + tab-complete typos meant
# we shipped a Dockerfile from the wrong source tree on at least 2 occasions
# in the 2026-05 cloud-deploy sprint. Guard is cheap, prevention is permanent.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/build-image.sh <expected-service-name> [docker-build-args...]" >&2
  exit 1
fi

EXPECTED_SVC="$1"
shift  # remaining args pass through to docker build

ACTUAL="$(basename "$PWD")"

if [[ "$ACTUAL" != "$EXPECTED_SVC" ]]; then
  echo "❌ wrong cwd: expected '$EXPECTED_SVC', got '$ACTUAL'" >&2
  echo "   cd into the correct service repo before running build-image.sh" >&2
  exit 1
fi

if [[ ! -f Dockerfile ]]; then
  echo "❌ no Dockerfile in $PWD — is this really a service repo root?" >&2
  exit 1
fi

echo "✓ cwd verified: $ACTUAL"
echo "→ docker build $*"
exec docker build "$@" .
