#!/usr/bin/env bats
# cast-hooks.bats — BATS test suite for cast-hooks

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# ── CLI tests ────────────────────────────────────────────────────────────────

@test "cast-hooks --version prints version matching VERSION file" {
  expected="cast-hooks v$(cat "$REPO_DIR/VERSION" | tr -d '[:space:]')"
  run bash "$REPO_DIR/bin/cast-hooks" --version
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "cast-hooks --help exits 0" {
  run bash "$REPO_DIR/bin/cast-hooks" --help
  [ "$status" -eq 0 ]
}

@test "cast-hooks list exits 0 and outputs table header" {
  run bash "$REPO_DIR/bin/cast-hooks" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Hook Registry"* ]]
}

# ── Hook script existence ────────────────────────────────────────────────────

@test "cast-session-start-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-session-start-hook.sh" ]
}

@test "cast-user-prompt-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-user-prompt-hook.sh" ]
}

@test "post-tool-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/post-tool-hook.sh" ]
}

@test "cast-tool-failure-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-tool-failure-hook.sh" ]
}

@test "cast-instructions-loaded-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-instructions-loaded-hook.sh" ]
}

@test "cast-audit-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-audit-hook.sh" ]
}

@test "pre-tool-guard.sh exists" {
  [ -f "$REPO_DIR/scripts/pre-tool-guard.sh" ]
}

@test "cast-headless-guard.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-headless-guard.sh" ]
}

@test "cast-session-end.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-session-end.sh" ]
}

@test "cast-subagent-start-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-subagent-start-hook.sh" ]
}

@test "cast-subagent-stop-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-subagent-stop-hook.sh" ]
}

@test "cast-pre-compact-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-pre-compact-hook.sh" ]
}

@test "cast-post-compact-hook.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-post-compact-hook.sh" ]
}

# ── Supporting script existence ──────────────────────────────────────────────

@test "cast-events.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-events.sh" ]
}

@test "cast_db.py exists" {
  [ -f "$REPO_DIR/scripts/cast_db.py" ]
}

@test "cast-db-log.py exists" {
  [ -f "$REPO_DIR/scripts/cast-db-log.py" ]
}

@test "cast-agent-run-log.py exists" {
  [ -f "$REPO_DIR/scripts/cast-agent-run-log.py" ]
}

@test "cast-log-append.py exists" {
  [ -f "$REPO_DIR/scripts/cast-log-append.py" ]
}

@test "cast-db-init.sh exists" {
  [ -f "$REPO_DIR/scripts/cast-db-init.sh" ]
}

# ── Script executability ─────────────────────────────────────────────────────

@test "all .sh scripts in scripts/ are executable" {
  for f in "$REPO_DIR/scripts/"*.sh; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || { echo "Not executable: $f"; return 1; }
  done
}

@test "all .py scripts in scripts/ are executable" {
  for f in "$REPO_DIR/scripts/"*.py; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || { echo "Not executable: $f"; return 1; }
  done
}

# ── Config validation ────────────────────────────────────────────────────────

@test "config/settings.json is valid JSON" {
  run python3 -c "import json; json.load(open('$REPO_DIR/config/settings.json'))"
  [ "$status" -eq 0 ]
}

@test "config/settings.json contains all 13 hook IDs" {
  run python3 -c "
import json
with open('$REPO_DIR/config/settings.json') as f:
    data = json.load(f)
ids = set()
for event, entries in data.get('hooks', {}).items():
    for entry in entries:
        if 'id' in entry:
            ids.add(entry['id'])
expected = {
    'cast-session-start', 'cast-user-prompt', 'cast-post-tool',
    'cast-tool-failure', 'cast-instructions', 'cast-audit',
    'cast-git-guard', 'cast-headless-guard', 'cast-session-end',
    'cast-subagent-start', 'cast-subagent-stop',
    'cast-pre-compact', 'cast-post-compact'
}
missing = expected - ids
if missing:
    print(f'Missing hook IDs: {missing}')
    exit(1)
print(f'All {len(expected)} hook IDs present')
"
  [ "$status" -eq 0 ]
}

# ── Syntax validation ────────────────────────────────────────────────────────

@test "bin/cast-hooks has valid bash syntax" {
  run bash -n "$REPO_DIR/bin/cast-hooks"
  [ "$status" -eq 0 ]
}

@test "install.sh has valid bash syntax" {
  run bash -n "$REPO_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "cast-merge-settings.sh has valid bash syntax" {
  run bash -n "$REPO_DIR/scripts/cast-merge-settings.sh"
  [ "$status" -eq 0 ]
}

@test "cast_db.py has valid Python syntax" {
  run python3 -c "import ast; ast.parse(open('$REPO_DIR/scripts/cast_db.py').read())"
  [ "$status" -eq 0 ]
}
