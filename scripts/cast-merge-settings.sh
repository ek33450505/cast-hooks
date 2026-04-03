#!/usr/bin/env bash
# cast-merge-settings.sh — Merge cast-hooks settings into user's settings.json
#
# Usage: bash cast-merge-settings.sh [--yes]
#   --yes  Skip confirmation prompt

set -uo pipefail

USER_SETTINGS="${HOME}/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_SETTINGS="${REPO_DIR}/config/settings.json"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m' C_GREEN='\033[0;32m' C_YELLOW='\033[0;33m' C_RED='\033[0;31m' C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_fail() { printf "${C_RED}  [fail]${C_RESET} %s\n" "$*" >&2; exit 1; }

# ── Validate source ──────────────────────────────────────────────────────────
if [ ! -f "$HOOKS_SETTINGS" ]; then
  _fail "Hook settings not found: $HOOKS_SETTINGS"
fi

python3 -c "import json; json.load(open('$HOOKS_SETTINGS'))" 2>/dev/null || _fail "Invalid JSON in $HOOKS_SETTINGS"

# ── Create user settings if missing ──────────────────────────────────────────
mkdir -p "${HOME}/.claude"
if [ ! -f "$USER_SETTINGS" ]; then
  echo '{}' > "$USER_SETTINGS"
  _ok "Created $USER_SETTINGS"
fi

# ── Confirmation ──────────────────────────────────────────────────────────────
if [ "${1:-}" != "--yes" ] && [ "${CI:-}" != "true" ]; then
  printf "\n${C_BOLD}Merge cast-hooks into ${USER_SETTINGS}?${C_RESET}\n"
  printf "  This will add/update hook entries. Existing non-hook settings are preserved.\n"
  printf "  A backup will be created first.\n\n"
  printf "  Proceed? [Y/n] "
  read -r reply 2>/dev/null || reply="n"
  case "${reply}" in
    [Yy]*|"") ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# ── Backup ────────────────────────────────────────────────────────────────────
BACKUP="${USER_SETTINGS}.bak"
cp "$USER_SETTINGS" "$BACKUP"
_ok "Backup saved to ${BACKUP}"

# ── Merge ─────────────────────────────────────────────────────────────────────
python3 << PYEOF
import json, sys

with open("$USER_SETTINGS") as f:
    user = json.load(f)

with open("$HOOKS_SETTINGS") as f:
    hooks = json.load(f)

# Merge hooks: for each event, add/update entries by id
if "hooks" not in user:
    user["hooks"] = {}

added = 0
updated = 0

for event, entries in hooks.get("hooks", {}).items():
    if event not in user["hooks"]:
        user["hooks"][event] = []

    existing_ids = {e.get("id") for e in user["hooks"][event] if isinstance(e, dict)}

    for entry in entries:
        entry_id = entry.get("id", "")
        if entry_id in existing_ids:
            # Update existing
            user["hooks"][event] = [entry if e.get("id") == entry_id else e for e in user["hooks"][event]]
            updated += 1
        else:
            user["hooks"][event].append(entry)
            added += 1

with open("$USER_SETTINGS", "w") as f:
    json.dump(user, f, indent=2)
    f.write("\n")

print(f"  Added {added} hook(s), updated {updated} hook(s)")
PYEOF

if [ $? -eq 0 ]; then
  _ok "Settings merged successfully"
else
  _fail "Merge failed — restoring backup"
  cp "$BACKUP" "$USER_SETTINGS"
fi
