# cast-hooks

[![CI](https://github.com/ek33450505/cast-hooks/actions/workflows/ci.yml/badge.svg)](https://github.com/ek33450505/cast-hooks/actions/workflows/ci.yml)
![version](https://img.shields.io/badge/version-0.2.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)
![hooks](https://img.shields.io/badge/hooks-13-purple)

13 lifecycle hook scripts that add observability, safety guards, and agent dispatch directives to Claude Code — without the full CAST agent team. Install cast-hooks for session tracking, tool audit trails, git safety guards, compaction recovery, and structured event logging. Works standalone with any Claude Code setup.

## What you get

Hook scripts are shell commands that Claude Code executes at specific lifecycle events — session start, tool use, agent dispatch, compaction, session end. They run automatically in the background, logging everything to `cast.db` (SQLite) and injecting directives like `[CAST-CHAIN]` and `[CAST-REVIEW]` into the conversation when conditions are met.

cast-hooks gives you the hook layer without requiring the full CAST framework, its 23 agents, or its orchestrator. Install the hooks, merge the settings, and Claude Code starts producing structured observability data immediately.

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

cast-hooks v0.2.0 — Hook Registry
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

cast-hooks v0.2.0 — Active Status
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

This copies all 20 scripts (13 hooks + 7 supporting) to `~/.claude/scripts/`, initializes the cast.db schema, and merges hook entries into your `~/.claude/settings.json`.

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

## Part of CAST

cast-hooks ships as part of the [CAST framework](https://github.com/ek33450505/claude-agent-team). If you install CAST, you get the full hook layer automatically. This standalone repo is for Claude Code users who want just the hooks — observability, safety gates, and dispatch directives — without the full agent team.

## CAST Ecosystem

> Auto-synced from [claude-agent-team/docs/ecosystem.md](https://github.com/ek33450505/claude-agent-team/blob/main/docs/ecosystem.md). Run `~/Projects/personal/claude-agent-team/scripts/sync-ecosystem-readme.sh` to refresh.

<!-- ECOSYSTEM_START -->
| Repo | Description | Latest | Install |
|---|---|---|---|
| [cast-hooks](https://github.com/ek33450505/cast-hooks) | 13 auditable hook scripts — observability, safety guards, quality gates. SessionStart, PreToolUse, PostToolUse, PostCompact. | ![](https://img.shields.io/github/v/release/ek33450505/cast-hooks?style=flat-square) | `brew tap ek33450505/cast-hooks && brew install cast-hooks` |
| [cast-agents](https://github.com/ek33450505/cast-agents) | 23 specialist agents — commit, debug, review, plan, test, research, and more. Agent definitions with YAML frontmatter. v7-synced. | ![](https://img.shields.io/github/v/release/ek33450505/cast-agents?style=flat-square) | `brew tap ek33450505/cast-agents && brew install cast-agents` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent agent memory with FTS5 search, relevance scoring, shared pool, semantic embeddings. Per-agent knowledge accumulation. | ![](https://img.shields.io/github/v/release/ek33450505/cast-memory?style=flat-square) | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-routines](https://github.com/ek33450505/cast-routines) | Scheduled autonomous Claude Code routines via YAML + cron. Daily briefings, inbox triage, release celebration, weekly cost reports. | ![](https://img.shields.io/github/v/release/ek33450505/cast-routines?style=flat-square) | `brew tap ek33450505/cast-routines && brew install cast-routines` |
| [cast-parallel](https://github.com/ek33450505/cast-parallel) | Parallel agent execution across worktree sessions. Agent Dispatch Manifest (ADM) support. | ![](https://img.shields.io/github/v/release/ek33450505/cast-parallel?style=flat-square) | `brew tap ek33450505/cast-parallel && brew install cast-parallel` |
| [cast-observe](https://github.com/ek33450505/cast-observe) | Session-level observability — cost tracking, agent run history, token spend, event sourcing. Feeds cast.db. | ![](https://img.shields.io/github/v/release/ek33450505/cast-observe?style=flat-square) | `brew tap ek33450505/cast-observe && brew install cast-observe` |
| [cast-security](https://github.com/ek33450505/cast-security) | Security hooks and audit trails. PII redaction, parry-guard integration, compliance logging. | ![](https://img.shields.io/github/v/release/ek33450505/cast-security?style=flat-square) | `brew tap ek33450505/cast-security && brew install cast-security` |
| [cast-doctor](https://github.com/ek33450505/cast-doctor) | Read-only health check for any Claude Code install. Validates hooks, MCP servers, agent frontmatter, cast.db schema, stale memories. | ![](https://img.shields.io/github/v/release/ek33450505/cast-doctor?style=flat-square) | `brew tap ek33450505/cast-doctor && brew install cast-doctor` |
| [cast-time](https://github.com/ek33450505/cast-time) | Gives Claude Code a clock — injects local time, timezone, and a semantic time-of-day bucket at every SessionStart. | ![](https://img.shields.io/github/v/release/ek33450505/cast-time?style=flat-square) | `brew tap ek33450505/cast-time && brew install cast-time` |
| [cast-dash](https://github.com/ek33450505/cast-dash) | Terminal UI dashboard for live swarm monitoring. 4-panel real-time display (Textual framework). | ![](https://img.shields.io/github/v/release/ek33450505/cast-dash?style=flat-square) | `brew tap ek33450505/cast-dash && brew install cast-dash` |
| [cast-claudes_journal](https://github.com/ek33450505/cast-claudes_journal) | Session continuity — Claude's Journal auto-injects prior-day context via SessionStart hook. Obsidian vault sync. | ![](https://img.shields.io/github/v/release/ek33450505/cast-claudes_journal?style=flat-square) | `brew tap ek33450505/homebrew-claudes-journal && brew install claudes-journal` |
| [cast-website](https://github.com/ek33450505/cast-website) | castframework.dev — marketing site and docs portal for the CAST ecosystem. | ![](https://img.shields.io/github/v/release/ek33450505/cast-website?style=flat-square) | — |
| [cast-desktop](https://github.com/ek33450505/cast-desktop) | Tauri 2 native app — embedded PTY terminal, command palette, 11 dashboard views, Constellation 3D graph. NEW. | ![](https://img.shields.io/github/v/release/ek33450505/cast-desktop?style=flat-square) | `brew tap ek33450505/homebrew-cast-desktop && brew install cast-desktop` |
<!-- ECOSYSTEM_END -->

## License

MIT — see [LICENSE](LICENSE)
