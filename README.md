# cast-hooks

[![CI](https://github.com/ek33450505/cast-hooks/actions/workflows/ci.yml/badge.svg)](https://github.com/ek33450505/cast-hooks/actions/workflows/ci.yml)
![version](https://img.shields.io/badge/version-0.1.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![hooks](https://img.shields.io/badge/hooks-13-purple)

13 lifecycle hook scripts that add observability, safety guards, and agent dispatch directives to Claude Code — without the full CAST agent team. Install cast-hooks for session tracking, tool audit trails, git safety guards, compaction recovery, and structured event logging. Works standalone with any Claude Code setup.

## What you get

Hook scripts are shell commands that Claude Code executes at specific lifecycle events — session start, tool use, agent dispatch, compaction, session end. They run automatically in the background, logging everything to `cast.db` (SQLite) and injecting directives like `[CAST-CHAIN]` and `[CAST-REVIEW]` into the conversation when conditions are met.

cast-hooks gives you the hook layer without requiring the full CAST framework, its 30 agents, or its orchestrator. Install the hooks, merge the settings, and Claude Code starts producing structured observability data immediately.

## Install

### Homebrew

```bash
brew tap ek33450505/cast-hooks
brew install cast-hooks
cast-hooks install
```

### Manual

```bash
git clone https://github.com/ek33450505/cast-hooks.git
cd cast-hooks
bash install.sh
```

## Hooks

| Hook ID | Event | Script | What it does |
|---|---|---|---|
| `cast-session-start` | SessionStart | `cast-session-start-hook.sh` | Initialize session, log to cast.db |
| `cast-user-prompt` | UserPromptSubmit | `cast-user-prompt-hook.sh` | Prompt analytics and tracking |
| `cast-post-tool` | PostToolUse | `post-tool-hook.sh` | CAST-CHAIN/CAST-REVIEW directives, ADM detection |
| `cast-tool-failure` | PostToolUseFailure | `cast-tool-failure-hook.sh` | Error logging for failed tool calls |
| `cast-instructions` | InstructionsLoaded | `cast-instructions-loaded-hook.sh` | Session context initialization |
| `cast-audit` | PreToolUse (Write\|Edit) | `cast-audit-hook.sh` | Audit trail for file changes |
| `cast-git-guard` | PreToolUse (Bash) | `pre-tool-guard.sh` | Git safety — blocks force-push, destructive ops |
| `cast-headless-guard` | PreToolUse (AskUserQuestion) | `cast-headless-guard.sh` | Blocks interactive prompts in headless/cron mode |
| `cast-session-end` | SessionEnd | `cast-session-end.sh` | Session cleanup, DB finalize |
| `cast-subagent-start` | SubagentStart | `cast-subagent-start-hook.sh` | Agent run logging (start) |
| `cast-subagent-stop` | SubagentStop | `cast-subagent-stop-hook.sh` | Agent run logging (completion) |
| `cast-pre-compact` | PreCompact | `cast-pre-compact-hook.sh` | Pre-compaction snapshot |
| `cast-post-compact` | PostCompact | `cast-post-compact-hook.sh` | Post-compaction recovery |

### Supporting scripts

| Script | Purpose |
|---|---|
| `cast-events.sh` | Event-sourcing protocol (sourced by multiple hooks) |
| `cast_db.py` | DB abstraction layer (WAL mode, swappable backend) |
| `cast-db-log.py` | Routing event dual-writer |
| `cast-agent-run-log.py` | Agent run logger |
| `cast-log-append.py` | JSONL append helper |
| `cast-db-init.sh` | DB schema initialization |

## Usage

### List all hooks

```
$ cast-hooks list

cast-hooks v0.1.0 — Hook Registry
════════════════════════════════════════════════════════════════════════════
  Hook ID                  Event                  Script                  Timeout  Async
  ──────────────────────────────────────────────────────────────────────────
  cast-session-start       SessionStart           cast-session-start-ho   5        no
  cast-user-prompt         UserPromptSubmit       cast-user-prompt-hook   5        no
  cast-post-tool           PostToolUse            post-tool-hook.sh       10       yes
  cast-tool-failure        PostToolUseFailure     cast-tool-failure-hoo   5        yes
  ...

13 hooks across 11 lifecycle events
```

### Check active status

```
$ cast-hooks status

cast-hooks v0.1.0 — Active Status
══════════════════════════════════════════════════════════════
  Hook ID                  Event                  Status
  ────────────────────────────────────────────────────────
  cast-session-start       SessionStart           active
  cast-user-prompt         UserPromptSubmit       active
  cast-post-tool           PostToolUse            active
  cast-git-guard           PreToolUse             inactive
  ...

  11 active, 2 inactive
```

### Install hooks

```bash
cast-hooks install
```

This copies all 19 scripts (13 hooks + 6 supporting) to `~/.claude/scripts/`, initializes the cast.db schema, and merges hook entries into your `~/.claude/settings.json`.

## How hooks work

Claude Code v4 hooks fire at lifecycle events. Each hook receives context as JSON on stdin:

```json
{
  "session_id": "abc123",
  "tool_name": "Bash",
  "tool_input": { "command": "git push --force" }
}
```

The hook script processes the event and responds:

- **Exit 0** — success (async hooks always exit 0)
- **Exit 2** — block the tool use (PreToolUse hooks only — used by `pre-tool-guard.sh` to block dangerous git commands)
- **stdout JSON** — `hookSpecificOutput` to inject directives into the conversation

## Configuration

Hooks are configured in `~/.claude/settings.json` under the `hooks` key. The template is at `config/settings.json` in this repo.

To enable or disable a specific hook, add or remove its entry from the appropriate lifecycle event in your settings file. Each hook entry has a unique `id` that `cast-hooks status` uses to detect whether it is active.

Timeout tuning: increase `timeout` values if hooks time out on slow machines. The defaults (3-15 seconds) work on most systems.

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI
- Bash 4+ (`brew install bash` on macOS)
- Python 3.9+
- SQLite3

## CAST Ecosystem

Each CAST component ships as a standalone Homebrew package. Mix and match to build your own stack.

| Package | What It Does | Install |
|---------|-------------|---------|
| [cast-agents](https://github.com/ek33450505/cast-agents) | 30 specialist Claude Code agents | `brew tap ek33450505/cast-agents && brew install cast-agents` |
| **cast-hooks** | 13 hook scripts — observability, safety gates, dispatch | `brew tap ek33450505/cast-hooks && brew install cast-hooks` |
| [cast-observe](https://github.com/ek33450505/cast-observe) | Session cost + token spend tracking | `brew tap ek33450505/cast-observe && brew install cast-observe` |
| [cast-security](https://github.com/ek33450505/cast-security) | Policy gates, PII redaction, audit trail | `brew tap ek33450505/cast-security && brew install cast-security` |
| [cast-dash](https://github.com/ek33450505/cast-dash) | Terminal UI dashboard (Python + Textual) | `brew tap ek33450505/cast-dash && brew install cast-dash` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent memory for Claude Code agents | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-parallel](https://github.com/ek33450505/cast-parallel) | Parallel plan execution across dual worktrees | `brew tap ek33450505/cast-parallel && brew install cast-parallel` |

## License

MIT — see [LICENSE](LICENSE)
