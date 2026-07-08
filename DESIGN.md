# Design: Codex → MiMoCode Subagent Skill

## Goal
Enable Codex to delegate complex tasks to MiMoCode as a headless subagent.

## Architecture

```
Codex (user-facing)
  │
  ├─ Triggers skill via description match
  │
  ├─ Builds prompt from user request
  │
  ├─ Calls bash tool → scripts/mimo-run.sh
  │     │
  │     ├─ Creates isolated MIMOCODE_HOME=$(mktemp -d)
  │     ├─ Runs: mimo run --format json --dangerously-skip-permissions --dir <workspace>
  │     ├─ Streams JSONL to stdout
  │     └─ Exits with mimo's exit code
  │
  ├─ Parses JSONL output (grep/jq or scripts/parse-mimo-output.sh)
  │
  └─ Reports results to user
```

## Decisions

### Invocation: Headless only
`mimo run --format json --dangerously-skip-permissions` — scriptable, no tmux needed, clean JSONL output.

### Isolation: Always fresh MIMOCODE_HOME
Every run gets `MIMOCODE_HOME=$(mktemp -d)` so it never touches the user's mimo config, memory, or sessions.

### Workspace: Shared via --dir
Codex and mimo share the same workspace directory (`--dir`). Files mimo creates are immediately visible to Codex. No copy-in/copy-out needed.

### Output: JSONL parsed by Codex
Codex reads JSONL events directly via grep/jq. A helper script (`parse-mimo-output.sh`) summarizes for quick extraction.

### When to use mimo
- Complex multi-step tasks (research, refactoring, multi-file changes)
- Tasks requiring file creation/modification at scale
- Anything mimo's compose agent handles well
- NOT for: simple questions, single-line edits, quick lookups

### Model selection
Default to mimo's configured model. Allow override via `--model` flag in the skill instructions.

## File Structure

```
Codex-MimoCode-Skill/
├── SKILL.md                    # Core skill file (loaded by Codex)
├── DESIGN.md                   # This file
├── scripts/
│   ├── mimo-run.sh             # Headless invocation wrapper
│   └── parse-mimo-output.sh    # JSONL → plain text summarizer
├── references/
│   └── jsonl-format.md         # JSONL event format reference
├── README.md                   # Documentation
├── LICENSE
└── .gitignore
```

## JSONL Event Format (Reference)

| Event | Key fields |
|-------|-----------|
| `text` | `part.text` — agent's text output |
| `tool_use` | `part.tool` (name), `part.state` (result) |
| `reasoning` | `part.text` — thinking (only with `--thinking`) |
| `error` | `error` — error details |
| `step_start` | step boundary |
| `step_finish` | step boundary |

Completion = process exit code 0, not a stream event.
