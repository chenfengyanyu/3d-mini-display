#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  BetterDisplay — One-click installer for macOS
# ─────────────────────────────────────────────

APP_NAME="BetterDisplay"
APP_PATH="/Applications/BetterDisplay.app"
CASK_NAME="betterdisplay"

# ── Colors ────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

# ── Platform check ────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  error "$APP_NAME only supports macOS. Current OS: $(uname)"
  exit 1
fi

echo ""
echo -e "${BOLD}  $APP_NAME Installer${RESET}"
echo "  ──────────────────────────────"
echo ""

# ── Already installed? ────────────────────────
if [[ -d "$APP_PATH" ]]; then
  warn "$APP_NAME is already installed at $APP_PATH"
  read -rp "  Launch it now? [Y/n] " choice
  choice="${choice:-Y}"
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    info "Launching $APP_NAME..."
    open "$APP_PATH"
    success "$APP_NAME launched."
  fi
  exit 0
fi

# ── Homebrew check / install ──────────────────
if ! command -v brew &>/dev/null; then
  warn "Homebrew not found. Installing Homebrew first..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for Apple Silicon
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  success "Homebrew installed."
else
  success "Homebrew found: $(brew --version | head -1)"
fi

# ── Install BetterDisplay ─────────────────────
info "Installing $APP_NAME via Homebrew..."
brew install --cask "$CASK_NAME"

# ── Verify installation ───────────────────────
if [[ ! -d "$APP_PATH" ]]; then
  error "Installation seems to have failed — $APP_PATH not found."
  exit 1
fi

success "$APP_NAME installed at $APP_PATH"

# ── Launch ────────────────────────────────────
info "Launching $APP_NAME..."
open "$APP_PATH"

echo ""
echo -e "${GREEN}${BOLD}  All done!${RESET} $APP_NAME is running in the menu bar."
echo ""
