#!/bin/bash
# install.sh — cast-hooks manual installer
# For users who clone the repo instead of using Homebrew.
#
# Usage: bash install.sh [--yes]

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CH_VERSION="$(cat "${REPO_DIR}/VERSION" 2>/dev/null || echo "unknown")"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'
  C_GREEN='\033[0;32m'
  C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'
  C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_fail() { printf "${C_RED}  [fail]${C_RESET} %s\n" "$*" >&2; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

# ── Banner ────────────────────────────────────────────────────────────────────
printf "\n${C_BOLD}cast-hooks v${CH_VERSION} installer${C_RESET}\n"
printf "══════════════════════════════════════\n\n"

# ── Step 1: Check prerequisites ──────────────────────────────────────────────
_step "Checking prerequisites..."
if ! command -v python3 &>/dev/null; then
  _warn "python3 not found — supporting scripts (cast_db.py, loggers) need Python 3.9+"
else
  _ok "python3 found"
fi

if ! command -v sqlite3 &>/dev/null; then
  _warn "sqlite3 not found — cast-db-init.sh needs sqlite3"
else
  _ok "sqlite3 found"
fi

# ── Step 2: Create directories ───────────────────────────────────────────────
_step "Creating directories..."
SCRIPTS_DST="${HOME}/.claude/scripts"
if mkdir -p "$SCRIPTS_DST" 2>/dev/null; then
  _ok "~/.claude/scripts/"
else
  _fail "Could not create ~/.claude/scripts/ — check permissions"
  exit 1
fi

# ── Step 3: Copy scripts ────────────────────────────────────────────────────
_step "Installing hook scripts..."
copied=0
errors=0
for f in "${REPO_DIR}/scripts/"*.sh "${REPO_DIR}/scripts/"*.py; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  dest="${SCRIPTS_DST}/${base}"
  if cp "$f" "$dest" 2>/dev/null; then
    chmod +x "$dest" 2>/dev/null || true
    _ok "${base}"
    copied=$((copied + 1))
  else
    _fail "Could not copy ${base}"
    errors=$((errors + 1))
  fi
done

if [ "$copied" -eq 0 ]; then
  _fail "No scripts found in ${REPO_DIR}/scripts/"
  exit 1
fi

if [ "$errors" -gt 0 ]; then
  _warn "${errors} script(s) failed to copy — check permissions"
fi

# ── Step 4: Initialize DB schema ────────────────────────────────────────────
_step "Initializing cast.db schema..."
if [ -f "${SCRIPTS_DST}/cast-db-init.sh" ]; then
  if bash "${SCRIPTS_DST}/cast-db-init.sh" 2>/dev/null; then
    _ok "cast.db schema initialized"
  else
    _warn "cast-db-init.sh had warnings (non-fatal)"
  fi
else
  _warn "cast-db-init.sh not found — DB schema not initialized"
fi

# ── Step 5: Merge settings ──────────────────────────────────────────────────
_step "Hook settings..."
MERGE_SCRIPT="${REPO_DIR}/scripts/cast-merge-settings.sh"

if [ "${1:-}" = "--yes" ] || [ "${CI:-}" = "true" ]; then
  if [ -f "$MERGE_SCRIPT" ]; then
    bash "$MERGE_SCRIPT" --yes
  else
    _warn "cast-merge-settings.sh not found"
  fi
else
  printf "  Merge cast-hooks settings into ~/.claude/settings.json? [Y/n] "
  read -r reply 2>/dev/null || reply="n"
  case "${reply}" in
    [Yy]*|"")
      if [ -f "$MERGE_SCRIPT" ]; then
        bash "$MERGE_SCRIPT" --yes
      else
        _warn "cast-merge-settings.sh not found"
      fi
      ;;
    *)
      _ok "Skipped — run manually: bash ${MERGE_SCRIPT}"
      ;;
  esac
fi

# ── Step 6: Symlink CLI ─────────────────────────────────────────────────────
_step "Installing CLI..."
LOCAL_BIN="${HOME}/.local/bin"
CLI_SRC="${REPO_DIR}/bin/cast-hooks"
CLI_DST="${LOCAL_BIN}/cast-hooks"

if mkdir -p "$LOCAL_BIN" 2>/dev/null; then
  if ln -sf "$CLI_SRC" "$CLI_DST" 2>/dev/null; then
    _ok "cast-hooks → ~/.local/bin/cast-hooks"
    if ! echo "$PATH" | grep -q "${LOCAL_BIN}"; then
      printf "\n  ${C_YELLOW}Note:${C_RESET} Add ~/.local/bin to your PATH:\n"
      printf "    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc\n"
    fi
  else
    _warn "Could not symlink to ~/.local/bin — run from repo: ${CLI_SRC}"
  fi
else
  _warn "Could not create ~/.local/bin — run from repo: ${CLI_SRC}"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
printf "\n${C_BOLD}══════════════════════════════════════${C_RESET}\n"
printf "${C_GREEN}cast-hooks v${CH_VERSION} installed.${C_RESET}\n\n"
printf "  Scripts: ${SCRIPTS_DST} (${copied} files)\n"
printf "  CLI:     ${CLI_DST}\n"
printf "\n${C_BOLD}Next steps:${C_RESET}\n"
printf "  1. Start Claude Code — hooks are now active\n"
printf "  2. Run: cast-hooks status\n"
printf "  3. Run: cast-hooks list\n\n"
