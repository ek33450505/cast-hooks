# Security Policy

## Supported Versions

| Version | Support Status |
|---|---|
| 0.1.x | Full support — security fixes backported |
| < 0.1 | No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately using [GitHub Security Advisories](https://github.com/ek33450505/cast-hooks/security/advisories/new).

### What to Include

- **cast-hooks version** — output of `cast-hooks --version`
- **Operating system** — macOS / Linux, version
- **Which file** — e.g., `install.sh`, `bin/cast-hooks`, specific hook script
- **Steps to reproduce** — minimal, clear reproduction steps
- **Impact** — what an attacker could do

### Response Timeline

| Severity | Acknowledgment | Fix Target |
|---|---|---|
| Critical | 48 hours | 14 days |
| High | 48 hours | 30 days |
| Medium / Low | 5 business days | Next release |

## Security Design Notes

cast-hooks ships shell and Python scripts that run as Claude Code lifecycle hooks. Key design decisions:

- **No remote network calls** — hook scripts operate locally on stdin JSON and local files only
- **Exit-code safety** — all async hooks exit 0 to avoid blocking Claude Code sessions
- **Pre-tool guards use exit 2** — only the git safety guard (`pre-tool-guard.sh`) and headless guard can block tool execution, and they do so explicitly via exit code 2
- **Settings merge creates backups** — `cast-merge-settings.sh` backs up `settings.json` before modifying it
- **install.sh is idempotent** — safe to re-run; copies files and sets permissions, does not execute hook logic
- **DB writes use WAL mode** — `cast_db.py` uses SQLite WAL for safe concurrent access
- **No credential storage** — hooks never read or write API keys, tokens, or secrets

## Out of Scope

- Vulnerabilities in the Claude API or Anthropic services — report to [Anthropic](https://www.anthropic.com/security)
- Vulnerabilities in third-party tools (bash, Python, SQLite, Homebrew)
- Issues requiring physical access to the machine
- Hook behavior customization — hooks are configuration, not security boundaries
