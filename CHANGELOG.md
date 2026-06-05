# Changelog

All notable changes to cast-hooks are documented here.

## [0.2.1] — 2026-06-05 — Security/correctness backport from flagship v7.4.1

### Fixed
- **cast-subagent-stop-hook.sh**: added the `STATUS_CONTRACT_EXEMPT` guard so built-in agents (general-purpose, Explore, Plan, claude, workflow-subagent) that return StructuredOutput no longer trigger false-positive `[CAST-TRUNCATED]` directives + DB writes.
- **pre-tool-guard.sh**: git-detection now tolerates global options (e.g. `git -C <path> commit` no longer bypasses the guard) and adds the git-stash block (`CAST_STASH_OK=1` escape hatch).
- **cast-db-init.sh**: provisions the full 38-table schema (was ~10) so co-installed CAST tools no longer fail/silently-drop writes to missing tables.
- **cast_db.py**: `ALLOWED_TABLES` now includes `task_queue`; `_allowed_db_prefixes` includes `/var/folders/` (macOS temp-dir test paths).

### Changed
- README: removed the fictional "Constellation 3D graph" claim; refreshed CAST ecosystem stats.

## [0.2.0] — 2026-05-11 — Polish + Ecosystem Sync

### Added
- Ecosystem cross-link section in README pointing to CAST framework components
- CI badge added to README header
- SubagentStop hook: wire Stop event, emit structured block JSON, add shape coverage (commit 0279a54)

### Changed
- pre-tool-guard.sh: switched python heredoc to single-quoted tag to silence shellcheck false-positives (commit 6367ce1)
- README agent count updated from 17 to 23 to match current CAST ecosystem (commit 6061028; corrected from the originally-noted "30" which was a transient overcount)

### Notes
- A v7 bulk script sync was attempted and reverted on 2026-05-11
  (commits 1283ca8 → 66e78d9) — bulk-copy broke 5 shape contract
  tests. cast-hooks's 13 hooks intentionally pin to the standalone-
  mode-compatible versions; per-script curation needed before any
  v7 features land. See cast-hooks issue tracker for the curation
  follow-up.

## [0.1.0] — 2026-04-03

### Added

- 13 Claude Code hook scripts covering all lifecycle events (SessionStart, UserPromptSubmit, PostToolUse, PostToolUseFailure, InstructionsLoaded, PreToolUse, SessionEnd, SubagentStart, SubagentStop, PreCompact, PostCompact)
- 6 supporting scripts (event-sourcing protocol, DB abstraction layer, routing logger, agent run logger, JSONL append helper, DB schema init)
- Pre-configured `settings.json` template with Claude Code v4 hook format (id, matcher, timeout, async)
- Settings merge utility (`cast-merge-settings.sh`) with backup and incremental merge
- `cast-hooks` CLI with `install`, `list`, `status` subcommands
- Homebrew formula for macOS/Linux install (`brew tap ek33450505/cast-hooks`)
- BATS test suite
