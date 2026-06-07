# MyBetterDisplay

> macOS 工具集：**Claude Code 状态可视化监控** + **BetterDisplay 非标分辨率输出**

---

## Claude Status Monitor

实时监控本机 Claude Code 的三种工作状态，通过可切换的动画主题在屏幕上直观展示。适合在副屏、浮窗或 BetterDisplay 虚拟屏上常驻显示。

### 状态说明

| 状态 | 颜色 | 含义 |
|------|------|------|
| 忙碌 | 🔴 红色 | Claude 正在思考 / 执行工具 |
| 等待（倒计时）| 🟡 黄色 | Claude 本轮结束，3 秒后无新事件自动转为空闲 |
| 等待（持续）| 🟡 黄色 | Claude 主动提问（AskUserQuestion），等待你的回复，不会自动转绿 |
| 空闲 | 🟢 绿色 | 任务全部完成，可发下一条消息 |

> 两次用户输入之间不会出现绿灯。绿灯表示 Claude 已完全停止工作，等待你的下一条消息。

### 快捷键

| 按键 | 功能 |
|------|------|
| `→` | 切换到下一个主题（循环） |
| `←` | 切换到上一个主题（循环） |

### 快速开始

```bash
bash start.sh
```

脚本自动完成：检查依赖 → 注入 hooks → 启动服务 → 打开浏览器。

停止服务：
```bash
bash stop.sh
```

### 30 个动画主题

| 图标 | 主题 | 视觉效果 |
|------|------|---------|
| 🚦 | 红绿灯 | 经典红黄绿三色灯 |
| ❤️ | 心电图 | 多种随机波形，心跳节律 |
| 🔮 | 呼吸球 | 多层同心圆脉动 |
| ✨ | 粒子漩涡 | 轨道粒子 + 湍流碰撞 |
| 💻 | 数字雨 | 二进制字符瀑布 |
| ⚡ | 雷电风暴 | 随机分叉闪电 |
| 🌌 | 极光 | 流动光带，Screen 叠色 |
| 📡 | 雷达扫描 | 旋转扫描 + 动态目标点 |
| 🌀 | 引力涟漪 | 同心圆爆发扩散 |
| 🫀 | 心跳脉冲 | 数学参数心形 + 弹簧物理 |
| 🌫️ | 流场烟雾 | Perlin 噪声粒子流 |
| 🎵 | 音频波形 | 频谱柱 + 镜像反射 |
| 🧊 | 旋转线框 | 3D 透视线框立方体 |
| ⏳ | 数字沙漏 | 粒子沙流物理模拟 |
| 🫧 | 熔岩灯 | Metaball 融合流动色块 |
| 🌠 | 星空 | 星云 + 流星 + 红灯时极速跃迁 |
| 😶 | 表情脸 | 抽象艺术脸：忙碌红眼生气、等待无奈问号、空闲开心笑容 |
| 🏗️ | 盖房子 | 像素积木逐层建造动画 |
| 🍉 | 切水果 | 忍者切水果风格粒子飞溅 |
| 🔥 | 火焰魂 | 粒子火焰：烈焰红 / 琥珀稳燃 / 幽灵寒焰 |
| 🧬 | DNA螺旋 | 3D 透视双螺旋旋转，碱基扫光 + 粒子飞散 |
| 💎 | 棱镜幻彩 | 旋转三棱柱折射彩虹光束，screen 叠加发光 |
| 🕐 | 赛博时钟 | 七段数码管真实时钟，状态变色 + glitch 故障效果 |
| 🤖 | 机器人 | 弹簧物理五官：齿轮眼/蒸汽/歪头问号/wink |
| 🐱 | 像素宠物 | 像素猫：忙碌敲键盘 / 无聊摇尾巴 / 酣睡 zzz |
| 🚀 | 飞船 HUD | 星舰驾驶舱：雷达 + 能量格 + RED ALERT 警报 |
| 🧠 | 神经网络 | 分层神经网络，激活脉冲粒子沿边传播 |
| 🌆 | 赛博城市 | 三层视差城市夜景，暴雨 / 暮色 / 繁星 |
| 📊 | 工作台 | 真实会话数据：工作计时 + 专注度 + 状态历史 |
| 🎯 | 像素格斗 | AI 对战：busy=连击，waiting=蓄力，idle=胜利 |

### 工作原理

```
用户发消息
  │
  ├─ UserPromptSubmit hook → set-state.sh busy      🔴 红灯
  │
  ├─ PreToolUse hook       → set-state.sh busy      🔴 红灯（持续）
  │    │
  │    └─ 若工具为 AskUserQuestion / AskFollowupQuestion
  │         → set-state.sh waiting (persistent)     🟡 黄灯（持续，不倒计时）
  │              └─ 等待用户回复后 → UserPromptSubmit 再次触发 → 回到红灯
  │
  ├─ Stop hook             → set-state.sh waiting   🟡 黄灯（3 秒倒计时）
  │    │
  │    └─ 若 Claude 继续工作（多 turn）→ PreToolUse 再次触发 → 回到红灯
  │
  └─ Stop hook 触发后 3 秒内无新事件
                              ↓
                    monitor.js 判定为 idle           🟢 绿灯
```

- **Hooks** 通过 `curl` POST 推送到 `monitor.js`（不再依赖文件）
- **monitor.js** 在内存维护状态：收到 `busy` 立即取消倒计时；收到 `waiting` 根据 `persistent` 字段决定行为——普通 Stop 启动 3 秒倒计时，`AskUserQuestion` 则持续黄灯直到用户回复
- **前端**每 250ms 轮询 `/api/status`，严格跟随服务端状态，通过 `postMessage` 同步给 iframe 主题
- **绿灯由服务端倒计时决定**：前端无任何计时逻辑

---

## BetterDisplay — 强制 480×640 非标分辨率

Mac 外接采集卡/设备无法识别非标分辨率时，通过 BetterDisplay 创建虚拟屏幕 + OBS/Parsec 串流输出。

安装 BetterDisplay：
```bash
bash install.sh
```

详细配置教程见 [INSTALL.md](./INSTALL.md)。

---

## 文件结构

```
MyBetterDisplay/
├── start.sh              # ⭐ 一键启动（首次运行这个就够了）
├── stop.sh               # 停止监控服务
├── install.sh            # 安装 BetterDisplay 应用
├── index.html            # 监控主页（主题切换器）
├── claude-status/
│   ├── monitor.js        # HTTP 监控服务（port 4242）
│   ├── set-state.sh      # Hook 脚本（由 Claude Code 调用）
│   └── install-hooks.sh  # 向 settings.json 注入 hooks
└── themes/               # 30 个动画主题（每个独立 HTML 文件）
```

## 系统要求

- macOS 12.0+（Intel / Apple Silicon）
- Node.js 16+（`brew install node`）
- Claude Code CLI
