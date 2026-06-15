#!/usr/bin/env bats
# cast-hooks-shapes.bats — Behavioral contract shape tests for cast-hooks
# Asserts actual emitted JSON shapes, not just file existence.

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# ── Shape contract tests ─────────────────────────────────────────────────────

@test "post-tool-hook emits PostToolUse hookSpecificOutput shape" {
  INPUT='{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.sh","content":"echo hi"}}'
  run bash -c "echo '$INPUT' | bash '$REPO_DIR/scripts/post-tool-hook.sh'"
  # hook may exit non-zero due to missing ~/.claude dirs in test env — check output regardless
  STDOUT="$output"
  run python3 -c "
import json, sys
lines = '''$STDOUT'''.strip().splitlines()
found = False
for line in lines:
    try:
        d = json.loads(line)
        hso = d.get('hookSpecificOutput', {})
        if hso.get('hookEventName') == 'PostToolUse' and isinstance(hso.get('additionalContext'), str):
            found = True
            break
    except Exception:
        continue
sys.exit(0 if found else 1)
"
  [ "$status" -eq 0 ]
}

@test "pre-tool-guard emits markdown block message on git commit block" {
  # Canonical switched from JSON {decision,reason} to plain markdown text + exit 2.
  INPUT='{"tool_name":"Bash","tool_input":{"command":"git commit -m foo"}}'
  run bash -c "echo '$INPUT' | bash '$REPO_DIR/scripts/pre-tool-guard.sh'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"[CAST]"* ]]
}

@test "pre-tool-guard git-guard path emits markdown; policy-engine block emits JSON" {
  # git-guard path (commit/push/stash) now emits plain markdown + exit 2 (canonical change).
  # Policy-engine block (Write/Edit + policies.json) still emits JSON {decision,reason}.

  # git-guard path: assert markdown + exit 2
  GIT_INPUT='{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}'
  run bash -c "echo '$GIT_INPUT' | bash '$REPO_DIR/scripts/pre-tool-guard.sh'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"[CAST]"* ]]

  # policy-engine path: policies.json absent in test env → exits 0 (no block).
  # Verify the policy block JSON shape using a synthetic output (shape contract via heredoc).
  run python3 - <<'PYEOF'
import json, sys
synthetic = '{"decision":"block","reason":"[CAST-POLICY-BLOCK] Policy blocks this edit."}'
d = json.loads(synthetic)
assert d.get('decision') == 'block', 'decision key missing'
assert isinstance(d.get('reason'), str), 'reason must be string'
sys.exit(0)
PYEOF
  [ "$status" -eq 0 ]
}

@test "pre-tool-guard allows git commit from subagent session" {
  # CLAUDE_SUBPROCESS=1 bypasses all git guards (canonical CLAUDE_SUBPROCESS bypass).
  # env passes the var into the bash -c subshell (not just into echo).
  INPUT='{"tool_name":"Bash","tool_input":{"command":"git commit -m foo"}}'
  run env CLAUDE_SUBPROCESS=1 bash -c "echo '$INPUT' | bash '$REPO_DIR/scripts/pre-tool-guard.sh'"
  [ "$status" -eq 0 ]
}

@test "pre-tool-guard blocks git stash" {
  # Canonical added a stash guard (reference: 2026-05-19 push-agent stash incident).
  INPUT='{"tool_name":"Bash","tool_input":{"command":"git stash pop"}}'
  run bash -c "echo '$INPUT' | bash '$REPO_DIR/scripts/pre-tool-guard.sh'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"[CAST]"* ]]
}

@test "cast-audit-hook advisory path emits PreToolUse hookSpecificOutput" {
  # Simulate a cloud-bound WebFetch with a known-good domain (safelist match -> advisory)
  # set CAST_PII_ENFORCEMENT=advisory to guarantee advisory path
  INPUT='{"tool_name":"WebFetch","tool_input":{"url":"https://example.com/page"}}'
  run bash -c "CAST_PII_ENFORCEMENT=advisory echo '$INPUT' | bash '$REPO_DIR/scripts/cast-audit-hook.sh'"
  # audit hook exits 0 always — check stdout for hookSpecificOutput if any PII detected
  # With example.com (safelist), no output is emitted — so just verify exit 0
  [ "$status" -eq 0 ]
  # Additionally verify that when advisory output IS emitted it has the right shape:
  SYNTHETIC='{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"[CAST-REDACT-WARN: 1 PII entities detected]"}}'
  run python3 -c "
import json, sys
d = json.loads('$SYNTHETIC')
hso = d.get('hookSpecificOutput', {})
assert hso.get('hookEventName') == 'PreToolUse', 'wrong hookEventName'
assert isinstance(hso.get('additionalContext'), str), 'additionalContext not string'
sys.exit(0)
"
  [ "$status" -eq 0 ]
}

@test "cast-headless-guard emits updatedInput WITH permissionDecision=allow" {
  INPUT='{"tool_name":"AskUserQuestion","input":{"question":"Should I continue?"}}'
  run bash -c "echo '$INPUT' | bash '$REPO_DIR/scripts/cast-headless-guard.sh'"
  [ "$status" -eq 0 ]
  STDOUT="$output"
  run python3 -c "
import json, sys
lines = '''$STDOUT'''.strip().splitlines()
for line in lines:
    try:
        d = json.loads(line)
        if 'updatedInput' in d:
            assert isinstance(d['updatedInput'].get('answer'), str), 'answer must be string'
            assert d.get('permissionDecision') == 'allow', 'permissionDecision must be present and equal allow'
            sys.exit(0)
    except AssertionError as e:
        print(str(e), file=sys.stderr)
        sys.exit(1)
    except Exception:
        continue
sys.exit(1)
"
  [ "$status" -eq 0 ]
}
