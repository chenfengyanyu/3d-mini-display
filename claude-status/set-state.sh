#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
#  Claude Code Status Hook
#  Usage: bash set-state.sh <busy|waiting>
#  Called by Claude Code hooks via settings.json
# ─────────────────────────────────────────────────────

STATE="${1:-waiting}"
MONITOR_URL="http://127.0.0.1:4242/api/state"

# Consume stdin (hook always pipes JSON, must drain it)
INPUT="$(cat)"

# Extract session_id from hook JSON (fallback to "unknown")
SESSION_ID="$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
SESSION_ID="${SESSION_ID:-unknown}"

# Extract hook event name
LAST_EVENT="$(echo "$INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
LAST_EVENT="${LAST_EVENT:-unknown}"

# POST state to monitor (fire-and-forget, ignore errors if server not running)
curl -sf -X POST "$MONITOR_URL" \
  -H "Content-Type: application/json" \
  -d "{\"state\":\"$STATE\",\"lastEvent\":\"$LAST_EVENT\",\"sessionId\":\"$SESSION_ID\"}" \
  -m 2 >/dev/null 2>&1 || true

exit 0
