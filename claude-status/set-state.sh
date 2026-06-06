#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
#  Claude Code Status Hook
#  Usage: bash set-state.sh <busy|waiting>
#  Called by Claude Code hooks via settings.json
#
#  State logic:
#    busy    → Claude is working / running tools      (红)
#    waiting → Claude is waiting for user input/reply (黄)
#
#  PreToolUse fires for ALL tools as "busy", but some
#  tools mean Claude is actually WAITING for the user:
#    - AskUserQuestion      (Claude asks the user a question)
#    - AskFollowupQuestion  (follow-up question to user)
#  These must be overridden to "waiting".
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

# ── Key fix: detect "waiting for user" tool calls ─────
# PreToolUse fires as "busy" for ALL tools, but
# AskUserQuestion / AskFollowupQuestion mean Claude is
# blocked waiting for the user → must show yellow.
if [[ "$STATE" == "busy" ]]; then
  TOOL_NAME="$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
  case "$TOOL_NAME" in
    AskUserQuestion|AskFollowupQuestion)
      STATE="waiting"
      ;;
  esac
fi

# ── Build payload ─────────────────────────────────────
# "waiting" from AskUserQuestion must stay yellow indefinitely
# (no auto-transition to idle) until the user actually replies.
# We signal this to the monitor with "persistent":true.
if [[ "$STATE" == "waiting" && "${TOOL_NAME:-}" =~ ^(AskUserQuestion|AskFollowupQuestion)$ ]]; then
  PERSISTENT="true"
else
  PERSISTENT="false"
fi

# POST state to monitor (fire-and-forget, ignore errors if server not running)
curl -sf -X POST "$MONITOR_URL" \
  -H "Content-Type: application/json" \
  -d "{\"state\":\"$STATE\",\"lastEvent\":\"$LAST_EVENT\",\"sessionId\":\"$SESSION_ID\",\"persistent\":$PERSISTENT}" \
  -m 2 >/dev/null 2>&1 || true

exit 0
