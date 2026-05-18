#!/usr/bin/env bash
# install.sh — top-level installer for hermes-setup.
#
# Idempotent. Refuses to run if any unreplaced <PLACEHOLDER> remains in
# the staging configs you intend to copy.
#
# What this does:
#   1. Verifies hermes-cli and (optionally) openclaw are installed.
#   2. Copies hermes/config.example.yaml → ~/.hermes/config.yaml (if missing).
#   3. Copies hermes/SOUL.example.md → ~/.hermes/SOUL.md (if missing).
#   4. Creates ~/.hermes/logs/ (launchd silently fails otherwise).
#   5. Substitutes <HOME> in launchd plists and installs them.
#   6. Runs the doctor.
#
# What this does NOT do:
#   - Install hermes-agent itself. See https://github.com/NousResearch/hermes-agent.
#   - Install OpenClaw itself. See https://docs.openclaw.ai.
#   - Provide API keys. Run `hermes-cli auth login` yourself.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

step()  { printf "\n\033[1;34m==>\033[0m %s\n" "$*"; }
ok()    { printf "    \033[32m✓\033[0m %s\n" "$*"; }
skip()  { printf "    \033[33m·\033[0m skip: %s\n" "$*"; }
die()   { printf "    \033[31m✗\033[0m %s\n" "$*" >&2; exit 1; }

run() {
  if (( DRY_RUN )); then
    printf "    [dry-run] %s\n" "$*"
  else
    eval "$@"
  fi
}

# ---------------------------------------------------------------------------
step "Preflight"

[[ "$(uname)" == "Darwin" ]] || die "This installer is macOS-only. (Mac mini target.)"
command -v hermes-cli >/dev/null 2>&1 || die "hermes-cli not on PATH. Install from https://github.com/NousResearch/hermes-agent first."
ok "hermes-cli: $(command -v hermes-cli)"
if command -v openclaw >/dev/null 2>&1; then
  ok "openclaw: $(command -v openclaw)"
else
  skip "openclaw not found (optional, but recommended for scheduled agent jobs)"
fi

# ---------------------------------------------------------------------------
step "Placeholder scan"

LEFTOVERS=$(grep -rl '<[A-Z][A-Z_]*>' "$REPO_ROOT/hermes" "$REPO_ROOT/openclaw" "$REPO_ROOT/launchd" 2>/dev/null || true)
if [[ -n "$LEFTOVERS" ]]; then
  echo "    The following staged files still contain <PLACEHOLDER> tokens:"
  printf '      %s\n' $LEFTOVERS
  echo ""
  echo "    Some are intentional (this installer rewrites <HOME> for you), but"
  echo "    please open each file and replace any <YOUR_*> tokens before"
  echo "    re-running this installer."
fi
ok "scan complete"

# ---------------------------------------------------------------------------
step "Install ~/.hermes/ configs"

mkdir -p "$HOME/.hermes/logs"
ok "~/.hermes/logs/ exists"

if [[ -f "$HOME/.hermes/config.yaml" ]]; then
  skip "~/.hermes/config.yaml already exists — leaving in place"
else
  run "cp '$REPO_ROOT/hermes/config.example.yaml' '$HOME/.hermes/config.yaml'"
  ok "wrote ~/.hermes/config.yaml"
fi

if [[ -f "$HOME/.hermes/SOUL.md" ]]; then
  skip "~/.hermes/SOUL.md already exists — leaving in place"
else
  run "cp '$REPO_ROOT/hermes/SOUL.example.md' '$HOME/.hermes/SOUL.md'"
  ok "wrote ~/.hermes/SOUL.md"
fi

# ---------------------------------------------------------------------------
step "Install launchd plists"

LA="$HOME/Library/LaunchAgents"
mkdir -p "$LA"

for plist in "$REPO_ROOT"/launchd/*.plist; do
  name=$(basename "$plist")
  target="$LA/$name"

  # com.example.* are pure samples — don't install by default.
  if [[ "$name" == com.example.* ]]; then
    skip "$name (sample only — copy and rename if you want it loaded)"
    continue
  fi

  if [[ -f "$target" ]]; then
    skip "$target already exists — leaving in place"
    continue
  fi

  run "sed 's|<HOME>|$HOME|g' '$plist' > '$target'"
  run "launchctl load '$target'"
  ok "loaded $name"
done

# ---------------------------------------------------------------------------
step "Doctor"
if [[ -x "$REPO_ROOT/tools/hermes-doctor.sh" ]]; then
  "$REPO_ROOT/tools/hermes-doctor.sh" || true
else
  skip "tools/hermes-doctor.sh missing"
fi

echo
echo "Done. Next:"
echo "  1. hermes-cli auth login                  # if you haven't already"
echo "  2. Edit ~/.hermes/config.yaml and ~/.hermes/SOUL.md to taste"
echo "  3. Edit ~/.openclaw/openclaw.json (use openclaw/openclaw.example.json as a starting point)"
echo "  4. Re-run ./tools/hermes-doctor.sh — should be all green"
