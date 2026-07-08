---
name: mimocode-subagent
description: "Use when you need to delegate a complex multi-step task to MiMoCode as a headless subagent. Triggers on: 'use mimocode', 'spawn mimo', 'delegate to mimo', 'mimo subagent', 'ask mimo to'. Use for: multi-file refactoring, research tasks, complex code generation, anything requiring multiple tool calls. Do NOT use for: simple questions, single-file edits, quick lookups — handle those directly."
---

# MiMoCode Subagent

Delegate complex tasks to MiMoCode running headlessly. MiMoCode gets its own tools (bash, read, write, grep, etc.) and works independently, returning results as structured output.

## When to Use

| Use MiMoCode | Handle directly |
|---|---|
| Multi-file refactoring | Single-line edit |
| Research & synthesis | Simple question |
| Complex code generation | Quick lookup |
| Tasks needing 5+ tool calls | 1-2 tool calls |

## How It Works

1. Codex builds a prompt describing the task
2. Calls `scripts/mimo-run.sh` which runs `mimo run --format json`
3. MiMoCode works independently in an isolated environment
4. JSONL output is parsed for text results and tool usage
5. Results are reported back

## Step-by-Step

### 1. Prepare the task prompt

Write a clear, self-contained prompt for MiMoCode. Include:
- What to do (specific, actionable)
- Where to do it (file paths, directory)
- Expected output (what "done" looks like)
- Any constraints (language, style, avoid certain patterns)

### 2. Invoke MiMoCode

```bash
# Basic invocation
echo "Your task prompt here" | bash scripts/mimo-run.sh --dir /path/to/workspace

# With model override
echo "Your task" | bash scripts/mimo-run.sh --dir /path/to/workspace --model "provider/model-name"

# With timeout (120 seconds)
echo "Your task" | bash scripts/mimo-run.sh --dir /path/to/workspace --timeout 120
```

The script outputs JSONL to stdout. Capture it:

```bash
OUTPUT=$(echo "Your task" | bash scripts/mimo-run.sh --dir /path/to/workspace 2>/tmp/mimo-stderr.log)
EXIT=$?
```

### 3. Parse the output

**Quick summary** (recommended — use the parser script):

```bash
echo "$OUTPUT" | bash scripts/parse-mimo-output.sh
```

This extracts text output, lists tools used, and reports errors.

**Manual parsing** for specific needs:

```bash
# Extract all text output
echo "$OUTPUT" | grep '"type":"text"' | jq -r '.part.text'

# Check which tools were used
echo "$OUTPUT" | jq -r 'select(.type=="tool_use") | .part.tool' | sort -u

# Check for errors
echo "$OUTPUT" | grep -q '"type":"error"' && echo "Errors detected"

# Get the last text block (often the summary)
echo "$OUTPUT" | grep '"type":"text"' | tail -1 | jq -r '.part.text'
```

### 4. Handle the result

- **Success (exit 0)**: Report MiMoCode's text output to the user
- **Failure (exit non-zero)**: Report the error, suggest retry or manual approach
- **Timeout**: MiMoCode took too long — simplify the task or increase timeout

### 5. File handoff

MiMoCode works in the `--dir` workspace. Files it creates/modifies are directly accessible:

```bash
# After mimo completes, files are in the workspace
ls /path/to/workspace/modified-file.txt
```

## Error Handling

| Error | Cause | Action |
|-------|-------|--------|
| `mimo: command not found` | MiMoCode not installed | Tell user to install MiMoCode |
| Exit code 124 | Timeout | Simplify task or increase `--timeout` |
| Exit code non-zero | MiMoCode error | Check stderr, report to user |
| Empty output | MiMoCode produced nothing | Check if prompt was valid |
| `type: error` in JSONL | Runtime error | Extract error message, report |

## Examples

### Example 1: Multi-file refactor
```
User: "Refactor all Python files in src/ to use async/await"

Codex:
1. echo "Refactor all Python files in src/ to use async/await. For each file: read it, identify sync functions that should be async, edit them, ensure imports are updated." | bash scripts/mimo-run.sh --dir /path/to/project
2. Parse output
3. Report: "MiMoCode refactored 5 files. Here's what changed: ..."
```

### Example 2: Research task
```
User: "Research the best approach for caching in our Express app"

Codex:
1. echo "Research caching approaches for an Express.js app. Look at the codebase structure, identify current caching patterns, and recommend an approach with pros/cons." | bash scripts/mimo-run.sh --dir /path/to/project
2. Parse output
3. Report MiMoCode's findings
```

## Quick Reference

| What | Command |
|------|---------|
| Run task | `echo "prompt" \| bash scripts/mimo-run.sh --dir <workspace>` |
| Parse output | `echo "$OUTPUT" \| bash scripts/parse-mimo-output.sh` |
| Get text only | `echo "$OUTPUT" \| grep '"type":"text"' \| jq -r '.part.text'` |
| Check exit | `EXIT=$?; [ $EXIT -eq 0 ] && echo "OK" \|\| echo "FAIL: $EXIT"` |
| Timeout | Add `--timeout 120` (seconds) |
