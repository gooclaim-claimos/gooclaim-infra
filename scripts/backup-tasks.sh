#!/bin/bash
# scripts/backup-tasks.sh
# Usage:
#   bash scripts/backup-tasks.sh
#
# Tars the local-only `tasks/` folder to `~/Documents/tasks-YYYY-MM-DD.tar.gz`.
# `tasks/` is gitignored (.gitignore:67) — this script is the ONLY durable
# backup of the Beta+Pilot execution tracker, daily logs, inventory, and
# completed-stage archives.
#
# Recommended cadence: run daily (e.g. via cron, launchd, or a daily reminder).
# Recommended retention: rotate manually after ~14 days; cumulative size is
# tiny (<5 MB even after months of work).
#
# Override paths via env vars:
#   REPO_ROOT=/path/to/Gooclaom-ClaimOS bash scripts/backup-tasks.sh
#   DEST_DIR=/path/to/backup-folder    bash scripts/backup-tasks.sh

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$HOME/Gooclaom-ClaimOS}"
DEST_DIR="${DEST_DIR:-$HOME/Documents}"
TS="$(date +%F)"
OUT="$DEST_DIR/tasks-$TS.tar.gz"

if [[ ! -d "$REPO_ROOT/tasks" ]]; then
  echo "❌ no tasks/ directory at $REPO_ROOT/tasks" >&2
  echo "   set REPO_ROOT env var if your repo lives elsewhere" >&2
  exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
  echo "❌ destination directory $DEST_DIR does not exist" >&2
  echo "   create it first or override with DEST_DIR=... env var" >&2
  exit 1
fi

tar czf "$OUT" -C "$REPO_ROOT" tasks/

SIZE="$(du -h "$OUT" | cut -f1)"
echo "✓ backup: $OUT ($SIZE)"
