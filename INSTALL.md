# 部署指南

> 面向零基础用户，从安装到看到信号灯，全程约 **5 分钟**。

---

## 第一步：确认前置条件

打开终端（Terminal），依次运行以下命令，确认都有输出：

```bash
# 检查系统（必须是 macOS）
sw_vers

# 检查 Node.js（需要 16 以上版本）
node --version
```

如果 `node --version` 报错，先安装 Node.js：

```bash
# 方式一：用 Homebrew（推荐）
brew install node

# 方式二：直接下载安装包
# 访问 https://nodejs.org，下载 LTS 版本安装即可
```

> Homebrew 本身没有？终端运行：
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```

---

## 第二步：下载项目

```bash
git clone https://github.com/wangjiatao/MyBetterDisplay.git
cd MyBetterDisplay
```

没有 Git？也可以直接在 GitHub 页面点 **Code → Download ZIP**，解压后进入目录。

---

## 第三步：一键启动

```bash
bash start.sh
```

脚本会自动完成所有事情：

```
✓ 检查 Node.js 环境
✓ 向 Claude Code 注入状态监听 Hooks
✓ 后台启动本地服务（端口 4242）
✓ 自动打开浏览器
```

浏览器弹出后，你会看到一个动画主题页面——这就说明部署成功了。

---

## 第四步：验证信号灯

打开 Claude Code，随便发一条消息，观察浏览器页面：

| 你的操作 | 信号灯变化 |
|---------|----------|
| 发送消息 | 🔴 红灯亮起 |
| Claude 思考 / 执行工具中 | 🔴 持续红灯 |
| Claude 回答完毕 | 🟡 黄灯（约 3 秒） |
| 3 秒后无新任务 | 🟢 绿灯，可以继续说话 |

---

## 日常使用

```bash
# 启动
bash start.sh

# 停止
bash stop.sh
```

服务在后台运行，**不影响电脑正常使用**。关闭浏览器标签不会停止服务，重启电脑后需要重新运行 `bash start.sh`。

---

## 主题切换

浏览器页面打开后，使用键盘方向键切换动画主题：

| 按键 | 效果 |
|------|------|
| `→` | 下一个主题 |
| `←` | 上一个主题 |
| `↑` | 跳到第一个 |
| `↓` | 跳到最后一个 |

也可以点击左下角 `⊞` 按钮打开主题选择菜单，共 **16 个主题**可选。

---

## 常见问题

**Q：运行 start.sh 提示"Node.js not found"**

```bash
brew install node
# 安装完重新运行 bash start.sh
```

---

**Q：浏览器打开了，但信号灯不动**

Hooks 可能没有注入成功，手动运行一次：

```bash
bash claude-status/install-hooks.sh
```

然后**重启 Claude Code**，再发一条消息测试。

---

**Q：端口 4242 被占用，服务启动失败**

```bash
lsof -ti:4242 | xargs kill -9
bash start.sh
```

---

**Q：想在副屏 / 竖屏上常驻显示**

直接把 `http://localhost:4242` 放到第二个浏览器窗口，拖到副屏全屏即可。

如果需要 480×640 非标分辨率虚拟屏，参考下方的 BetterDisplay 章节。

---

## 可选：BetterDisplay 虚拟屏（进阶）

**适用场景**：采集卡/外接设备不支持非标分辨率，需要创建一个 480×640 的虚拟屏来串流显示信号灯。

### 安装

```bash
bash install.sh
# 等价于：brew install --cask betterdisplay
```

### 创建虚拟屏幕

1. 打开 BetterDisplay，允许「屏幕录制」和「辅助功能」权限
2. 点击菜单栏图标 → **Create New Virtual Display**
3. 分辨率手动输入 `480 × 640`（不要从列表选），刷新率 60Hz，竖屏
4. 系统设置 → 显示器，确认虚拟屏已出现

### 串流到采集卡

- **OBS**：添加来源 → 显示器捕获 → 选虚拟屏 → 变换选「自由比例」
- **Parsec / 向日葵**：选虚拟屏作为捕获源，关闭自动适配，手动锁定 480×640

---

## 卸载

```bash
# 停止服务
bash stop.sh

# 删除项目目录
cd .. && rm -rf MyBetterDisplay

# 移除注入的 Hooks（手动编辑 ~/.claude/settings.json，删除含 set-state.sh 的条目）
```
