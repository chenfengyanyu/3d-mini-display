# 安装与使用指南

## 目录

1. [Claude Status Monitor 快速上手](#一claude-status-monitor-快速上手)
2. [手动配置](#二手动配置)
3. [主题开发](#三主题开发)
4. [BetterDisplay 480×640 教程](#四betterdisplay-强制设置-480640-分辨率)
5. [常见问题](#五常见问题)

---

## 一、Claude Status Monitor 快速上手

### 前置要求

| 依赖 | 检查方式 | 安装方式 |
|------|---------|---------|
| macOS 12.0+ | `sw_vers` | — |
| Node.js 16+ | `node --version` | `brew install node` |
| Claude Code | `claude --version` | [claude.ai/code](https://claude.ai/code) |

### 一键启动

```bash
bash start.sh
```

**第一次运行**会自动完成：
1. 检查 Node.js 环境
2. 向 `~/.claude/settings.json` 注入三条 hooks
3. 后台启动 HTTP 监控服务（端口 4242）
4. 打开浏览器 `http://localhost:4242`

**再次运行**：如果服务已在运行，直接打开浏览器，不重复启动。

### 停止服务

```bash
bash stop.sh
```

### 访问地址

| 地址 | 说明 |
|------|------|
| `http://localhost:4242` | 主题切换器主页 |
| `http://localhost:4242/api/status` | 状态 JSON 接口（供下游程序使用） |

### API 响应格式

```json
{
  "state":     "busy | waiting | idle",
  "lastEvent": "UserPromptSubmit | PreToolUse | Stop",
  "sessionId": "会话ID",
  "updatedAt": 1748578800
}
```

**状态枚举：**
- `busy` — Claude 正在思考或执行工具（红色）
- `waiting` — Claude 本轮结束（黄色，5 秒后自动变绿）
- `idle` — 无活跃任务（绿色，等待下一条消息）

---

## 二、手动配置

### 手动安装 Hooks

```bash
bash claude-status/install-hooks.sh
```

验证是否成功：

```bash
node -e "
const s = JSON.parse(require('fs').readFileSync(
  process.env.HOME+'/.claude/settings.json','utf8'));
const h = s.hooks || {};
['UserPromptSubmit','PreToolUse','Stop'].forEach(ev => {
  const ok = (h[ev]||[]).some(g=>g.hooks?.some(x=>x.command?.includes('set-state')));
  console.log(ev + ':', ok ? '✓' : '✗');
});
"
```

### 手动启动服务

```bash
# 前台运行（可看日志）
node claude-status/monitor.js

# 后台运行
nohup node claude-status/monitor.js > /tmp/claude-status.log 2>&1 &
```

### Hook 工作原理

Claude Code 在特定时机执行 `set-state.sh`，脚本写入两个文件：

```
~/.claude/claude-status.json    — 当前状态（state/lastEvent/sessionId）
~/.claude/claude-prompt-marker  — UserPromptSubmit 标记（任务进行中时存在）
```

**标记文件的作用**：`PreToolUse` 会频繁覆盖 `lastEvent`，导致前端收不到 `UserPromptSubmit` 信号。标记文件作为持久化凭据，在任务结束（`Stop`）时才删除，保证整个任务过程中 API 始终返回 `UserPromptSubmit` 作为 `lastEvent`。

---

## 三、主题开发

每个主题是独立的 HTML 文件，放在 `themes/<id>/index.html`。

### 添加新主题

1. 新建目录：`mkdir themes/my-theme`
2. 创建 `themes/my-theme/index.html`，实现以下接口：

```javascript
// 接收来自父页面的状态变化
window.addEventListener('message', ({ data }) => {
  if (data?.state) setMyState(data.state, data.lastEvent);
});

// 状态机（所有主题使用统一模板）
const YELLOW_MS = 5000;
let wTimer = null, greenLocked = false;

function setState(s, ev) {
  const fresh = ev === 'UserPromptSubmit';
  if (s === 'busy') {
    if ((greenLocked || wTimer) && !fresh) return;
    if (wTimer) { clearTimeout(wTimer); wTimer = null; }
    if (fresh) greenLocked = false;
    applyState('busy'); return;
  }
  if (s === 'idle') {
    if (wTimer) return;
    greenLocked = false; applyState('idle'); return;
  }
  if (greenLocked || wTimer) return;
  applyState('waiting');
  wTimer = setTimeout(() => {
    wTimer = null; greenLocked = true; applyState('idle');
  }, YELLOW_MS);
}
```

3. 在 `index.html` 的 `THEMES` 数组中注册：

```javascript
const THEMES = [
  // ... 现有主题
  { id: 'my-theme', name: '我的主题', icon: '🎨' },
];
```

### 三种状态的视觉设计规范

| 状态 | 推荐颜色 | 动画特征 |
|------|---------|---------|
| busy | `#ff3b30`（红） | 快速、剧烈、高能量 |
| waiting | `#ffcc00`（黄） | 中等节奏，过渡感 |
| idle | `#34c759`（绿） | 缓慢、平静、极低能耗 |

---

## 四、BetterDisplay 强制设置 480×640 分辨率

**适用场景**：Mac 外接采集卡/设备无法识别 480×640 等非标分辨率，通过创建虚拟屏幕 + 串流软件输出。

### 准备工作

| 软件 | 用途 | 获取 |
|------|------|------|
| BetterDisplay | 创建虚拟屏幕 | `bash install.sh` |
| OBS Studio | 采集卡/直播输出 | [obsproject.com](https://obsproject.com) |
| Parsec / 向日葵 | 投屏远程 | 按需选择 |

安装 BetterDisplay：
```bash
bash install.sh
# 或手动：brew install --cask betterdisplay
```

### 创建 480×640 虚拟屏幕

1. **授权**：首次打开允许「屏幕录制」和「辅助功能」权限
2. **新建虚拟显示器**：点击菜单栏图标 → Create New Virtual Display

   | 参数 | 值 |
   |------|------|
   | Resolution | **手动输入** `480 × 640`（不要从列表选） |
   | Refresh Rate | `60Hz` |
   | Orientation | 竖屏 |

3. **确认**：系统设置 → 显示器，按住 Option 点击「显示器设置」确认分辨率

### 串流输出

**OBS 采集（采集卡/直播）：**
1. 添加来源 → 显示器捕获 → 选择刚创建的虚拟屏
2. 右键 → 变换 → 编辑变换 → 适配方式选**「自由比例」**

**Parsec/向日葵：**
1. 选择虚拟屏作为捕获源
2. 关闭「自动适配屏幕」，手动锁定 480×640

---

## 五、常见问题

**Q：start.sh 提示 "Node.js not found"**
```bash
brew install node
```

**Q：Hooks 安装失败**
```bash
bash claude-status/install-hooks.sh
```
检查 `~/.claude/settings.json` 是否存在且可写。

**Q：thinking 过程显示绿灯**

确认 hooks 已正确安装（见上方验证命令）。绿灯问题排查：
```bash
# 检查标记文件
ls -la ~/.claude/claude-prompt-marker
# 检查 API 返回
curl http://localhost:4242/api/status
```

**Q：端口 4242 被占用**
```bash
lsof -ti:4242 | xargs kill -9
bash start.sh
```

**Q：Homebrew 安装慢**
```bash
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
```

**Q：BetterDisplay 虚拟屏创建失败**

系统设置 → 隐私与安全性 → 确认 BetterDisplay 已开启辅助功能 + 屏幕录制权限。

**Q：卸载 BetterDisplay**
```bash
brew uninstall --cask betterdisplay
```
