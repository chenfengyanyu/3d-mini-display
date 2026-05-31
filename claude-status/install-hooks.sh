#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
#  Install Claude Code Status Hooks
#  Injects PreToolUse / UserPromptSubmit / Stop hooks
#  into ~/.claude/settings.json
# ─────────────────────────────────────────────────────
set -euo pipefail

SETTINGS_FILE="${HOME}/.claude/settings.json"
SET_STATE_SCRIPT="$(cd "$(dirname "$0")" && pwd)/set-state.sh"
BACKUP_FILE="${SETTINGS_FILE}.backup.$(date +%Y%m%d%H%M%S)"

# ── Colors ─────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }

# ── Preflight ──────────────────────────────────────
if [[ ! -f "$SETTINGS_FILE" ]]; then
  warn "~/.claude/settings.json not found. Creating a new one."
  echo '{}' > "$SETTINGS_FILE"
fi

if ! command -v node &>/dev/null; then
  echo "Error: node is required but not found." >&2
  exit 1
fi

chmod +x "$SET_STATE_SCRIPT"

# ── Backup ─────────────────────────────────────────
cp "$SETTINGS_FILE" "$BACKUP_FILE"
info "Backed up settings to: $BACKUP_FILE"

# ── Inject hooks via Node.js ───────────────────────
info "Injecting hooks into $SETTINGS_FILE ..."

node - "$SETTINGS_FILE" "$SET_STATE_SCRIPT" <<'NODEJS'
const fs      = require('fs');
const [,, settingsPath, scriptPath] = process.argv;

const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
settings.hooks = settings.hooks || {};

const HOOK_ID = 'claude-status-monitor';

// Define the three hooks we need
const hookDefs = [
  {
    event: 'UserPromptSubmit',
    state: 'busy',
    comment: 'User sent message → Claude starts working',
  },
  {
    event: 'PreToolUse',
    state: 'busy',
    comment: 'Tool execution begins → Claude is busy',
  },
  {
    event: 'Stop',
    state: 'waiting',
    comment: 'Claude finished its turn → waiting for user',
  },
];

for (const { event, state } of hookDefs) {
  settings.hooks[event] = settings.hooks[event] || [];

  // Skip if this hook is already installed (idempotent)
  const alreadyInstalled = settings.hooks[event].some(group =>
    Array.isArray(group.hooks) &&
    group.hooks.some(h => h.command && h.command.includes('claude-status'))
  );

  if (alreadyInstalled) {
    console.log(`  skip  ${event} (already installed)`);
    continue;
  }

  settings.hooks[event].push({
    matcher: '',
    hooks: [
      {
        type: 'command',
        command: `bash "${scriptPath}" ${state}`,
        timeout: 5,
      },
    ],
  });

  console.log(`  added  ${event} → ${state}`);
}

// Atomic write
const tmp = settingsPath + '.tmp.' + process.pid;
fs.writeFileSync(tmp, JSON.stringify(settings, null, 2) + '\n');
fs.renameSync(tmp, settingsPath);
NODEJS

success "Hooks installed successfully."
echo ""
echo "  Hook mapping:"
echo "    UserPromptSubmit  →  busy    (Claude received your message)"
echo "    PreToolUse        →  busy    (Claude is executing a tool)"
echo "    Stop              →  waiting (Claude finished, awaiting your reply)"
echo ""
echo "  To start the monitor server:"
echo "    node $(cd "$(dirname "$0")" && pwd)/monitor.js"
echo ""
