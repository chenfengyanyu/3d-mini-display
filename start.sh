#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
#  Claude Status Monitor — One-click Startup
#  用法: bash start.sh
#
#  做了什么:
#    1. 检查 Node.js 依赖
#    2. 向 ~/.claude/settings.json 注入 hooks（幂等，已有则跳过）
#    3. 启动 HTTP 监控服务（端口 4242，后台运行）
#    4. 自动打开浏览器
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'; RED='\033[0;31m'
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=4242
PID_FILE="/tmp/claude-status-monitor.pid"
LOG_FILE="/tmp/claude-status-monitor.log"

echo ""
echo -e "${BOLD}  Claude Status Monitor${RESET}"
echo "  ─────────────────────────────────────────"
echo ""

# ── 1. 平台检查 ──────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  error "仅支持 macOS。"; exit 1
fi

# ── 2. Node.js 检查 ──────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  error "需要 Node.js，但未找到。"
  info  "安装方式："
  info  "  Homebrew:  brew install node"
  info  "  官网:      https://nodejs.org"
  exit 1
fi
success "Node.js $(node --version)"

# ── 3. 注入 Claude Code hooks ────────────────────────────────────
info "检查 Claude Code hooks..."
if bash "$SCRIPT_DIR/claude-status/install-hooks.sh" > /dev/null 2>&1; then
  success "Hooks 已就绪"
else
  warn "Hooks 自动安装失败，请手动运行:"
  echo "    bash claude-status/install-hooks.sh"
fi

# ── 4. 启动监控服务 ──────────────────────────────────────────────
if lsof -ti:$PORT &>/dev/null; then
  success "监控服务已在运行 (port $PORT)"
  open "http://localhost:$PORT"
  echo ""
  echo -e "  ${BOLD}浏览器已打开:${RESET} ${CYAN}http://localhost:$PORT${RESET}"
  echo -e "  停止服务: ${CYAN}bash stop.sh${RESET}"
  echo ""
  exit 0
fi

info "启动监控服务..."
nohup node "$SCRIPT_DIR/claude-status/monitor.js" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

# 等待服务就绪（最多 3 秒）
for i in $(seq 1 12); do
  sleep 0.25
  curl -s "http://localhost:$PORT/api/status" &>/dev/null && break
done

if ! curl -s "http://localhost:$PORT/api/status" &>/dev/null; then
  error "服务启动失败，查看日志: $LOG_FILE"
  cat "$LOG_FILE" | tail -10
  exit 1
fi

success "服务已启动  pid=$(cat $PID_FILE)  port=$PORT"
success "API    → http://localhost:$PORT/api/status"
success "App    → http://localhost:$PORT"

# ── 5. 打开浏览器 ────────────────────────────────────────────────
sleep 0.3
open "http://localhost:$PORT"

echo ""
echo -e "  ${BOLD}启动完成！${RESET} Claude Status Monitor 正在运行。"
echo -e "  停止服务: ${CYAN}bash stop.sh${RESET}"
echo -e "  日志文件: ${CYAN}$LOG_FILE${RESET}"
echo ""
