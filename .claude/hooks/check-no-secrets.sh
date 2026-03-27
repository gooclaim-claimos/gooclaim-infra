#!/bin/bash
# Hook: block if file contains potential secrets
# Runs before every Write/Edit in Claude Code

FILE="$1"

# Patterns that should never be in code
if grep -qE "(password|secret|api_key|private_key)\s*=\s*['\"][^'\"]{8,}" "$FILE" 2>/dev/null; then
  echo "ERROR: Potential hardcoded secret detected in $FILE. Use AWS Secrets Manager." >&2
  exit 1
fi

exit 0
