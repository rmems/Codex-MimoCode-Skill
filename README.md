# Codex-MimoCode-Skill

A Codex skill that lets Codex delegate complex tasks to MiMoCode as a headless subagent.

## What It Does

When Codex encounters a multi-step task (research, refactoring, multi-file changes), this skill lets it spawn MiMoCode to handle the heavy lifting. MiMoCode runs headlessly with its own tool set, and returns structured results.

```
User → Codex → skill triggers → mimo run (headless) → JSONL output → Codex parses → result
```

## Prerequisites

- [MiMoCode](https://github.com/anthropics/mimocode) installed and on PATH
- `jq` for JSON parsing
- Codex CLI

## Installation

```bash
# Clone into Codex skills directory
git clone https://github.com/rmems/Codex-MimoCode-Skill.git ~/.codex/skills/mimocode-subagent

# Or symlink
ln -s /path/to/Codex-MimoCode-Skill ~/.codex/skills/mimocode-subagent
```

## Usage

The skill triggers automatically when you ask Codex to use MiMoCode:

- "Use mimocode to refactor all Python files in src/"
- "Spawn mimo to research the best caching approach"
- "Ask mimo to generate a REST API from this schema"

## Architecture

```
Codex-MimoCode-Skill/
├── SKILL.md                    # Skill instructions (loaded by Codex)
├── DESIGN.md                   # Architecture decisions
├── scripts/
│   ├── mimo-run.sh             # Headless invocation wrapper
│   └── parse-mimo-output.sh    # JSONL → plain text summarizer
├── references/
│   └── jsonl-format.md         # JSONL event format reference
└── README.md
```

### How It Works

1. Codex detects a task suitable for MiMoCode (via skill description matching)
2. Builds a clear, self-contained prompt
3. Calls `scripts/mimo-run.sh --dir <workspace>` via bash tool
4. MiMoCode runs headlessly with `--dangerously-skip-permissions`
5. JSONL events stream to stdout
6. Codex parses output with `scripts/parse-mimo-output.sh` or grep/jq
7. Results are reported to the user

### Isolation

Each MiMoCode run gets:
- Fresh `MIMOCODE_HOME=$(mktemp -d)` — no shared config/memory/sessions
- Shared workspace via `--dir` — files are immediately visible to both agents

## Scripts

### mimo-run.sh

```bash
echo "Your task" | bash scripts/mimo-run.sh --dir /path/to/workspace
```

Flags:
- `--dir PATH` — Working directory (required)
- `--model MODEL` — Override model
- `--agent AGENT` — Override agent (e.g. "compose")
- `--timeout SECS` — Timeout in seconds (default: 300)
- `--file PATH` — Attach a file
- `--thinking` — Enable reasoning output

### parse-mimo-output.sh

```bash
echo "$JSONL_OUTPUT" | bash scripts/parse-mimo-output.sh
```

Summarizes JSONL to: text output, tools used, errors.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `mimo: command not found` | Install MiMoCode: `npm i -g @anthropic-ai/mimocode` |
| Timeout (exit 124) | Increase `--timeout` or simplify the task |
| No output | Check if prompt was valid; check stderr |
| Errors in output | Check `parse-mimo-output.sh` for error details |

## Future: MiMoCode → Codex

See [Issue #9](https://github.com/rmems/Codex-MimoCode-Skill/issues/9) for the reverse direction — MiMoCode spawning Codex as a subagent.

## License

See [LICENSE](LICENSE).
