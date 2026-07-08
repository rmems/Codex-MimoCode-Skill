# MiMoCode JSONL Event Format

Reference for parsing `mimo run --format json` output.

## Event Structure

Every event is one JSON object per line:

```json
{"type": "<event_type>", "timestamp": <ms>, "sessionID": "ses_...", ...payload}
```

## Event Types

### text
Agent's text output.

```json
{"type":"text","timestamp":1234567890,"sessionID":"ses_abc","part":{"type":"text","text":"I'll create the file..."}}
```

Extract: `.part.text`

### tool_use
Tool invocation (emitted once when completed or errored).

```json
{"type":"tool_use","timestamp":1234567890,"sessionID":"ses_abc","part":{"type":"tool","tool":"write","state":{"status":"completed","output":"File created"}}}
```

Extract: `.part.tool` (name), `.part.state` (result)

### reasoning
Thinking content (only with `--thinking` flag).

```json
{"type":"reasoning","timestamp":1234567890,"sessionID":"ses_abc","part":{"type":"reasoning","text":"The user wants..."}}
```

Extract: `.part.text`

### error
Runtime error.

```json
{"type":"error","timestamp":1234567890,"sessionID":"ses_abc","error":{"message":"..."}}
```

### step_start / step_finish
Step boundaries. Useful for progress tracking.

## Key Parsing Rules

1. **No `session.id` event** — sessionID is a field on each event
2. **No `tool_result` event** — results are in `tool_use.part.state`
3. **Completion = process exit code 0**, not a stream event
4. **`tool_use.part.tool`** is a bare string (e.g. `"write"`), not an object
5. **Text lives at `.part.text`**, not top-level `.text`

## Quick Parse Patterns

```bash
# All text output
grep '"type":"text"' output.jsonl | jq -r '.part.text'

# Tools used
jq -r 'select(.type=="tool_use") | .part.tool' output.jsonl | sort -u

# Errors
grep '"type":"error"' output.jsonl

# Last text block (often the summary)
grep '"type":"text"' output.jsonl | tail -1 | jq -r '.part.text'

# Check if write tool was used
grep -q '"tool":"write"' output.jsonl && echo "Files were written"
```
