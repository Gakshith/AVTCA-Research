#!/usr/bin/env bash
# Codex login for remote SFSU workspace (device-auth disabled).
# Run ON srva. Port 1455 must be FREE — codex login binds it itself.
# Forward port 1455 from your LAPTOP (Cursor Ports panel or ssh -L) so the
# browser OAuth callback can reach srva.

set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
PORT=1455

echo "==> Stopping stale Codex processes..."
pkill -f 'codex app-server' 2>/dev/null || true
pkill -f 'codex login' 2>/dev/null || true
sleep 1

echo "==> Clearing revoked credentials..."
codex logout 2>/dev/null || true
rm -f "$CODEX_HOME/auth.json"

if ss -tln 2>/dev/null | grep -q ":${PORT} "; then
  echo ""
  echo "ERROR: Port ${PORT} is already in use on srva."
  echo "Something else is bound to it (often a mistaken ssh -L run ON srva)."
  echo ""
  echo "  Fix — kill whatever holds the port, then re-run this script:"
  echo "    pkill -f 'ssh.*${PORT}'"
  echo "    pkill -f 'codex login'"
  echo ""
  echo "  Do NOT run this on srva (it steals port ${PORT}):"
  echo "    ssh -L ${PORT}:localhost:${PORT} 922933190@srva   # WRONG — run on laptop"
  echo ""
  ss -tlnp 2>/dev/null | grep ":${PORT} " || true
  exit 1
fi

echo "==> Port ${PORT} is free. Starting browser login..."
echo ""
echo "    BEFORE completing sign-in, forward port ${PORT} from your LAPTOP:"
echo "      Cursor: Ports panel → Forward port ${PORT}"
echo "      Or laptop terminal: ssh -L ${PORT}:localhost:${PORT} 922933190@srva"
echo ""
codex login

echo ""
echo "==> Verifying API access..."
if codex exec "reply with exactly: ok" --dangerously-bypass-approvals-and-sandbox 2>&1 | head -5 | grep -qi ok; then
  echo "SUCCESS: Codex auth is working."
  codex login status
  exit 0
fi

echo "WARNING: Login finished but API test did not return 'ok'."
echo "  - Close Codex on your laptop (only one active session)."
echo "  - Do NOT use: codex login --device-auth (disabled for SFSU)."
echo "  - Re-run this script after: codex logout (on laptop and srva)."
codex login status
exit 1
