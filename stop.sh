#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
#  Claude Status Monitor — Stop Service
#  用法: bash stop.sh
# ─────────────────────────────────────────────────────

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
PID_FILE="/tmp/claude-status-monitor.pid"
PORT=4242

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    rm -f "$PID_FILE"
    echo -e "${GREEN}[OK]${RESET}    监控服务已停止 (pid: $PID)"
  else
    echo -e "${YELLOW}[WARN]${RESET}  进程不存在，清理 pid 文件"
    rm -f "$PID_FILE"
  fi
else
  # 尝试通过端口杀进程
  PIDS="$(lsof -ti:$PORT 2>/dev/null)"
  if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill 2>/dev/null
    echo -e "${GREEN}[OK]${RESET}    监控服务已停止"
  else
    echo -e "${YELLOW}[WARN]${RESET}  监控服务未在运行"
  fi
fi
