#!/usr/bin/env bash
# hermes-doctor.sh — quick health check for a Mac mini hermes-agent install.
#
# Verifies: ~/.hermes exists, gateway daemon is loaded, log dirs exist,
# launchd plist is registered, openclaw is on PATH.
#
# Usage:  ./tools/hermes-doctor.sh
#         ./tools/hermes-doctor.sh --remote mac-mini   # run over ssh

set -uo pipefail

REMOTE=""
if [[ "${1:-}" == "--remote" && -n "${2:-}" ]]; then
  REMOTE="$2"
  exec ssh -o ConnectTimeout=10 "$REMOTE" "bash -s" -- < "$0"
fi

ok()    { printf "  [\033[32mok\033[0m]   %s\n" "$*"; }
warn()  { printf "  [\033[33mwarn\033[0m] %s\n" "$*"; }
fail()  { printf "  [\033[31mfail\033[0m] %s\n" "$*"; FAILS=$((FAILS+1)); }
FAILS=0

echo
echo "hermes-doctor: $(uname -n) ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
echo

# 1. hermes home
if [[ -d "$HOME/.hermes" ]]; then
  ok "~/.hermes exists"
else
  fail "~/.hermes missing — run \`hermes-cli config init\`"
fi

# 2. config
if [[ -f "$HOME/.hermes/config.yaml" ]]; then
  ok "~/.hermes/config.yaml present ($(wc -c < "$HOME/.hermes/config.yaml") bytes)"
else
  fail "~/.hermes/config.yaml missing"
fi

# 3. auth
if [[ -f "$HOME/.hermes/auth.json" ]]; then
  ok "~/.hermes/auth.json present (run \`hermes-cli auth login\` if stale)"
else
  warn "~/.hermes/auth.json missing — run \`hermes-cli auth login\`"
fi

# 4. log dir
if [[ -d "$HOME/.hermes/logs" ]]; then
  ok "log directory exists"
else
  warn "~/.hermes/logs missing — launchd will silently fail to start"
fi

# 5. launchd plist
PLIST_NAME="ai.hermes.gateway"
if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
  ok "launchd: $PLIST_NAME loaded"
else
  warn "launchd: $PLIST_NAME not loaded — install from launchd/ai.hermes.gateway.plist"
fi

# 6. binaries on PATH
for bin in hermes-cli openclaw; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin found at $(command -v $bin)"
  else
    warn "$bin not on PATH"
  fi
done

# 7. <PLACEHOLDER> leftovers in installed configs
if [[ -f "$HOME/.hermes/config.yaml" ]] && grep -q '<[A-Z_]*>' "$HOME/.hermes/config.yaml"; then
  fail "~/.hermes/config.yaml still has unreplaced <PLACEHOLDER> values"
fi
if [[ -f "$HOME/.openclaw/openclaw.json" ]] && grep -q '<[A-Z_]*>' "$HOME/.openclaw/openclaw.json"; then
  fail "~/.openclaw/openclaw.json still has unreplaced <PLACEHOLDER> values"
fi

echo
if (( FAILS == 0 )); then
  echo "All checks passed."
  exit 0
else
  echo "$FAILS check(s) failed."
  exit 1
fi
