#!/usr/bin/env bash
# mimo-run.sh — Headless MiMoCode invocation wrapper
# Runs mimo with isolated MIMOCODE_HOME and streams JSONL output.
#
# Usage:
#   echo "Your task" | bash scripts/mimo-run.sh --dir /path/to/workspace
#   bash scripts/mimo-run.sh --dir /path/to/workspace <<< "Your task"
#   bash scripts/mimo-run.sh --dir /path/to/workspace --model "provider/model" --timeout 120 <<< "task"
#
# Flags:
#   --dir PATH       Working directory for mimo (required)
#   --model MODEL    Override model (e.g. "provider/model-name")
#   --agent AGENT    Override agent (e.g. "compose")
#   --timeout SECS   Timeout in seconds (default: 300)
#   --file PATH      Attach a file to the mimo session
#   --thinking       Enable reasoning output (--thinking flag to mimo)
#
# Output: JSONL events to stdout
# Exit: mimo's exit code, or 124 on timeout, or 1 on setup error

set -euo pipefail

# --- Defaults ---
WORKDIR=""
MODEL=""
AGENT=""
TIMEOUT=300
FILE=""
THINKING=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)       WORKDIR="$2"; shift 2 ;;
    --model)     MODEL="$2"; shift 2 ;;
    --agent)     AGENT="$2"; shift 2 ;;
    --timeout)   TIMEOUT="$2"; shift 2 ;;
    --file)      FILE="$2"; shift 2 ;;
    --thinking)  THINKING=true; shift ;;
    *)           echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# --- Validate ---
if [[ -z "$WORKDIR" ]]; then
  echo "Error: --dir is required" >&2
  echo "Usage: bash scripts/mimo-run.sh --dir /path/to/workspace <<< 'task'" >&2
  exit 1
fi

if [[ ! -d "$WORKDIR" ]]; then
  echo "Error: workspace directory does not exist: $WORKDIR" >&2
  exit 1
fi

if ! command -v mimo &>/dev/null; then
  echo "Error: mimo not found on PATH. Install MiMoCode first." >&2
  exit 1
fi

# --- Build mimo command ---
MHOME=$(mktemp -d)
trap 'rm -rf "$MHOME"' EXIT

CMD=(mimo run --format json --dangerously-skip-permissions --dir "$WORKDIR")

[[ -n "$MODEL" ]]  && CMD+=(--model "$MODEL")
[[ -n "$AGENT" ]]  && CMD+=(--agent "$AGENT")
[[ -n "$FILE" ]]   && CMD+=(--file "$FILE")
[[ "$THINKING" == true ]] && CMD+=(--thinking)

# --- Run with timeout ---
MIMOCODE_HOME="$MHOME" timeout "$TIMEOUT" "${CMD[@]}"
EXIT=$?

# --- Translate timeout exit code ---
if [[ $EXIT -eq 124 ]]; then
  echo "Error: mimo timed out after ${TIMEOUT}s" >&2
fi

exit $EXIT
