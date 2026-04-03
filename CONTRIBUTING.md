# Contributing to cast-hooks

Thank you for your interest in cast-hooks! This guide covers how to add hooks, modify existing ones, and contribute tests.

## Prerequisites

- **bats-core** — test runner for the BATS test suite
- **Bash 4+** — all scripts target Bash 4 (macOS ships Bash 3; install via `brew install bash`)
- **Python 3.9+** — required by supporting scripts (`cast_db.py`, `cast-db-log.py`, etc.)
- **Claude Code CLI** — for testing hooks end-to-end

## Quick Start

```bash
git clone https://github.com/ek33450505/cast-hooks
cd cast-hooks
bash install.sh
bats tests/
```

## Hook File Format

Hooks are registered in `config/settings.json` using the Claude Code v4 hook format. Each lifecycle event contains an array of hook entries:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "id": "cast-session-start",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/cast-session-start-hook.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Required fields per hook entry:

| Field | Description |
|---|---|
| `id` | Unique hook identifier (used by `cast-hooks status` to detect active hooks) |
| `hooks[].type` | Always `"command"` for shell hooks |
| `hooks[].command` | Shell command to execute (absolute path to script) |
| `hooks[].timeout` | Max execution time in seconds |

Optional fields:

| Field | Description |
|---|---|
| `matcher` | Regex pattern to filter which tools trigger the hook (e.g., `"Write\|Edit"`) |
| `hooks[].async` | `true` to run hook asynchronously (non-blocking) |

## How Hooks Work

Claude Code lifecycle hooks receive context on **stdin** as JSON. The hook script reads stdin, processes the event, and communicates back via:

- **Exit code 0** — success (or no-op for async hooks)
- **Exit code 2** — block the tool use (PreToolUse hooks only)
- **stdout JSON** — `hookSpecificOutput` field for injecting directives into the conversation

## Adding a New Hook

1. Create the script in `scripts/` (e.g., `scripts/my-hook.sh`)
2. Make it executable: `chmod +x scripts/my-hook.sh`
3. Add an entry to `config/settings.json` under the appropriate lifecycle event
4. Update the hook table in `README.md`
5. Add the script to the copy list in `install.sh`
6. Add existence and executability checks in `tests/cast-hooks.bats`

## Testing Guide

Tests live in `tests/cast-hooks.bats`. Run them with:

```bash
bats tests/
```

Test coverage includes:
- CLI subcommands (`--version`, `list`, `status`)
- Script existence and executability for all hooks
- JSON validity of `config/settings.json`
- Bash syntax validation (`bash -n`) for all shell scripts

For end-to-end hook testing, install hooks into a Claude Code session and verify behavior manually.

## PR Checklist

- [ ] `bats tests/` passes locally
- [ ] New hook: script exists in `scripts/` and is executable
- [ ] New hook: entry added to `config/settings.json` with id, type, command, timeout
- [ ] New hook: added to the hooks table in `README.md`
- [ ] New hook: added to `install.sh` copy list
- [ ] New hook: existence test added in `tests/cast-hooks.bats`
- [ ] `CHANGELOG.md` updated for any user-visible changes
- [ ] No hardcoded absolute paths in scripts — use `$HOME` or env vars
