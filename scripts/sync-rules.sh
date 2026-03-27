#!/bin/bash
# sync-rules.sh
# Syncs .claude/ rules and skills from gooclaim-infra to service repos.
# SAFE: only touches .claude/ — never src/, tests/, migrations/, or any code.
#
# Usage:
#   bash scripts/sync-rules.sh                    → sync all service repos
#   bash scripts/sync-rules.sh gooclaim-engine    → sync one repo
#   bash scripts/sync-rules.sh --check            → dry run, show what would change
#
# Run from: gooclaim-infra root
# When to run: after updating any file in templates/.claude/ or .claude/hooks/

set -e

DRY_RUN=false
TARGET_REPO=""

# Parse args
for arg in "$@"; do
  case "$arg" in
    --check) DRY_RUN=true ;;
    *)       TARGET_REPO="$arg" ;;
  esac
done

# All known service repos
ALL_REPOS=(
  gooclaim-gateway
  gooclaim-engine
  gooclaim-truth
  gooclaim-knowledge
  gooclaim-learning
  gooclaim-outbound
  gooclaim-policy
  gooclaim-observe
  gooclaim-audit
  gooclaim-shared
)

# If specific repo given, only do that one
if [ -n "$TARGET_REPO" ]; then
  ALL_REPOS=("$TARGET_REPO")
fi

UPDATED=0
SKIPPED=0
NOT_FOUND=0

echo ""
echo "Gooclaim Rules Sync"
echo "Source: templates/.claude/"
echo "Mode:   $([ "$DRY_RUN" = true ] && echo 'DRY RUN (--check)' || echo 'LIVE')"
echo "────────────────────────────────────────"

# ─── Helper: get version from a file ─────────────────────
get_version() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "0.0"
    return
  fi
  # Rules files: <!-- rules-version: X.Y -->
  # Skills files: rules-version: "X.Y" in frontmatter
  grep -m1 'rules-version' "$file" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "0.0"
}

# ─── Helper: sync one file ────────────────────────────────
sync_file() {
  local src="$1"
  local dest="$2"
  local label="$3"

  local src_ver dest_ver
  src_ver=$(get_version "$src")
  dest_ver=$(get_version "$dest")

  if [ ! -f "$dest" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [NEW]    $label (v$src_ver)"
    else
      cp "$src" "$dest"
      echo "  [NEW]    $label (v$src_ver)"
    fi
    UPDATED=$((UPDATED + 1))
  elif [ "$src_ver" = "$dest_ver" ]; then
    echo "  [OK]     $label (v$src_ver)"
    SKIPPED=$((SKIPPED + 1))
  else
    if [ "$DRY_RUN" = true ]; then
      echo "  [UPDATE] $label (v$dest_ver → v$src_ver)"
    else
      cp "$src" "$dest"
      echo "  [UPDATE] $label (v$dest_ver → v$src_ver)"
    fi
    UPDATED=$((UPDATED + 1))
  fi
}

# Helper: sync raw file by content (for non-versioned files like JSON/shell hooks)
sync_raw_file() {
  local src="$1"
  local dest="$2"
  local label="$3"

  if [ ! -f "$dest" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [NEW]    $label"
    else
      cp "$src" "$dest"
      echo "  [NEW]    $label"
    fi
    UPDATED=$((UPDATED + 1))
  elif cmp -s "$src" "$dest"; then
    echo "  [OK]     $label"
    SKIPPED=$((SKIPPED + 1))
  else
    if [ "$DRY_RUN" = true ]; then
      echo "  [UPDATE] $label"
    else
      cp "$src" "$dest"
      echo "  [UPDATE] $label"
    fi
    UPDATED=$((UPDATED + 1))
  fi
}

# ─── Layer rule mapping ───────────────────────────────────
get_layer_rule() {
  local repo="$1"
  case "$repo" in
    *gateway*)  echo "l0-gateway.md" ;;
    *engine*)   echo "l1-workflow.md" ;;
    *truth*)    echo "l2-truth.md" ;;
    *knowledge*)echo "l3-knowledge.md" ;;
    *learning*) echo "l4-learning.md" ;;
    *outbound*) echo "l5-outbound.md" ;;
    *policy*)   echo "l6-policy.md" ;;
    *observe*)  echo "l7-observe.md" ;;
    *)          echo "" ;;
  esac
}

# ─── Main sync loop ───────────────────────────────────────
for REPO in "${ALL_REPOS[@]}"; do
  REPO_PATH="../$REPO"

  if [ ! -d "$REPO_PATH" ]; then
    echo ""
    echo "$REPO  [NOT FOUND — skipping]"
    NOT_FOUND=$((NOT_FOUND + 1))
    continue
  fi

  # Safety check — abort if uncommitted changes in .claude/
  if [ "$DRY_RUN" = false ]; then
    if cd "$REPO_PATH" 2>/dev/null && git diff --quiet HEAD -- .claude/ 2>/dev/null; then
      cd - > /dev/null
    else
      cd - > /dev/null 2>/dev/null || true
      echo ""
      echo "$REPO  [SKIPPED — uncommitted changes in .claude/. Commit or stash first.]"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  fi

  echo ""
  echo "$REPO"

  # Ensure .claude dirs exist
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$REPO_PATH/.claude/rules"
    mkdir -p "$REPO_PATH/.claude/skills"
    mkdir -p "$REPO_PATH/.claude/hooks"
  fi

  # Sync layer-specific rule
  LAYER_RULE=$(get_layer_rule "$REPO")
  if [ -n "$LAYER_RULE" ]; then
    sync_file \
      "templates/.claude/rules/$LAYER_RULE" \
      "$REPO_PATH/.claude/rules/$LAYER_RULE" \
      "rules/$LAYER_RULE"
  fi

  # Sync all 4 skills
  for skill in docs.md new-adr.md session-end.md test.md; do
    sync_file \
      "templates/.claude/skills/$skill" \
      "$REPO_PATH/.claude/skills/$skill" \
      "skills/$skill"
  done

  # Sync hooks
  sync_raw_file \
    ".claude/hooks/check-no-secrets.sh" \
    "$REPO_PATH/.claude/hooks/check-no-secrets.sh" \
    "hooks/check-no-secrets.sh"

  # Sync Claude settings (hook schema, matchers, etc.)
  sync_raw_file \
    ".claude/settings.json" \
    "$REPO_PATH/.claude/settings.json" \
    "settings.json"

done

# ─── Summary ─────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────"
echo "Updated:   $UPDATED files"
echo "Up-to-date: $SKIPPED files"
[ $NOT_FOUND -gt 0 ] && echo "Not found: $NOT_FOUND repos (not cloned locally)"
echo ""
if [ "$DRY_RUN" = true ]; then
  echo "Dry run — no files changed. Run without --check to apply."
fi
