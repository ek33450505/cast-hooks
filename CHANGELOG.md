# Changelog

All notable changes to cast-hooks are documented here.

## [0.1.0] — 2026-04-03

### Added

- 13 Claude Code hook scripts covering all lifecycle events (SessionStart, UserPromptSubmit, PostToolUse, PostToolUseFailure, InstructionsLoaded, PreToolUse, SessionEnd, SubagentStart, SubagentStop, PreCompact, PostCompact)
- 6 supporting scripts (event-sourcing protocol, DB abstraction layer, routing logger, agent run logger, JSONL append helper, DB schema init)
- Pre-configured `settings.json` template with Claude Code v4 hook format (id, matcher, timeout, async)
- Settings merge utility (`cast-merge-settings.sh`) with backup and incremental merge
- `cast-hooks` CLI with `install`, `list`, `status` subcommands
- Homebrew formula for macOS/Linux install (`brew tap ek33450505/cast-hooks`)
- BATS test suite
