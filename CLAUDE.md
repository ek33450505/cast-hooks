# cast-hooks

## Install

```bash
bash install.sh          # copies scripts to ~/.claude/scripts/, merges settings.json, symlinks CLI
bash install.sh --yes    # non-interactive (CI / scripted)
```

Prerequisites: Bash 4+, Python 3.9+, sqlite3.

## Test

```bash
bats tests/
```

BATS tests that touch $HOME must use an isolated temp HOME — never run against the real $HOME.

## Run

```bash
cast-hooks status   # check which hooks are active in ~/.claude/settings.json
cast-hooks list     # show all 13 hooks with event, script, timeout, async flag
cast-hooks install  # re-run the install flow (idempotent)
```

## Non-obvious

- Hook output **must** use `hookSpecificOutput` JSON format — non-spec stdout is a hard CI fail.
- Exit 0 = pass, exit 2 = block tool (PreToolUse only); async hooks must always exit 0.
- `cast-merge-settings.sh` merges hook entries into `~/.claude/settings.json`; it does not overwrite existing keys.
- DB path: `CAST_DB_PATH` env var overrides the default `~/.claude/cast.db`.
- `cast_db.py` is the only sanctioned DB abstraction — never call sqlite3 directly from hook scripts.
