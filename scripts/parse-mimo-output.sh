#!/usr/bin/env bash
# parse-mimo-output.sh — Summarize MiMoCode JSONL output to plain text
#
# Usage:
#   echo "$JSONL_OUTPUT" | bash scripts/parse-mimo-output.sh
#   bash scripts/parse-mimo-output.sh < output.jsonl
#
# Output: Human-readable summary of the mimo run

set -euo pipefail

INPUT=$(cat)

# --- Extract text output ---
TEXTS=$(echo "$INPUT" | grep '"type":"text"' 2>/dev/null | jq -r '.part.text' 2>/dev/null || true)

# --- Extract tools used ---
TOOLS=$(echo "$INPUT" | jq -r 'select(.type=="tool_use") | .part.tool' 2>/dev/null | sort -u || true)

# --- Extract errors ---
ERRORS=$(echo "$INPUT" | grep '"type":"error"' 2>/dev/null | jq -r '.error' 2>/dev/null || true)

# --- Count events ---
TEXT_COUNT=0; TOOL_COUNT=0; ERROR_COUNT=0
[[ -n "$TEXTS" ]]   && TEXT_COUNT=$(echo "$TEXTS" | wc -l | tr -d ' ')
[[ -n "$TOOLS" ]]   && TOOL_COUNT=$(echo "$TOOLS" | wc -l | tr -d ' ')
[[ -n "$ERRORS" ]]  && ERROR_COUNT=$(echo "$ERRORS" | wc -l | tr -d ' ')

# --- Output summary ---
echo "=== MiMoCode Output Summary ==="
echo ""

if [[ $ERROR_COUNT -gt 0 ]]; then
  echo "--- ERRORS ($ERROR_COUNT) ---"
  echo "$ERRORS"
  echo ""
fi

if [[ $TOOL_COUNT -gt 0 ]]; then
  echo "--- Tools Used ($TOOL_COUNT) ---"
  echo "$TOOLS"
  echo ""
fi

if [[ $TEXT_COUNT -gt 0 ]]; then
  echo "--- Agent Output ($TEXT_COUNT messages) ---"
  echo "$TEXTS"
else
  echo "(No text output from mimo)"
fi

echo ""
echo "=== End Summary ==="
