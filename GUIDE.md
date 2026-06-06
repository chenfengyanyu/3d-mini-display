# 使用说明（五分钟上手）

## 这是什么？

**一句话：让你能直观看到 Claude 现在在不在忙。**

打开网页后，屏幕上会显示一个会动的信号灯：
- 🔴 **红色** = Claude 正在处理你的请求，稍等一下
- 🟡 **黄色** = Claude 刚回复完（约 3 秒后转绿），或 Claude 正在等你回答它提的问题（持续黄灯，不自动转绿）
- 🟢 **绿色** = Claude 空闲了，可以发下一条消息

---

## 第一次使用，按这三步走

### 第一步：确认电脑上有 Node.js

打开 **终端**（按 `Command + 空格`，搜索"终端"），粘贴以下命令并回车：

```bash
node --version
```

- 如果显示类似 `v18.0.0` 的数字 → 直接跳到第二步 ✅
- 如果提示"找不到命令" → 先运行下面这行安装：

```bash
brew install node
```

> 没有 Homebrew？把这行粘贴到终端运行（很长，完整复制）：
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```
> 装完再运行 `brew install node`。

---

### 第二步：下载项目

```bash
git clone https://github.com/wangjiatao/MyBetterDisplay.git
cd MyBetterDisplay
```

> 不会 git？去 GitHub 页面点 **Code → Download ZIP**，下载后解压，把文件夹拖到桌面，然后在终端输入：
> ```bash
> cd ~/Desktop/MyBetterDisplay
> ```

---

### 第三步：一键启动

```bash
bash start.sh
```

等几秒，浏览器会自动弹出一个动画页面——**看到动画就说明成功了**。

---

## 日常用法

每次开机后，只需要在终端运行：

```bash
bash start.sh
```

不用的时候关掉：

```bash
bash stop.sh
```

---

## 切换动画主题

网页打开后，按键盘方向键换主题：

| 按键 | 效果 |
|------|------|
| `→` | 下一个主题 |
| `←` | 上一个主题 |
| `↑` | 跳到第一个 |
| `↓` | 跳到最后一个 |

也可以点左下角的 `⊞` 按钮，从 22 个主题里挑一个。

---

## 遇到问题怎么办

**问题 1：运行 start.sh 提示"Node.js not found"**

```bash
brew install node
```
装完重新运行 `bash start.sh`。

---

**问题 2：浏览器打开了，但颜色一直不变**

手动重装一下钩子，然后重启 Claude Code：

```bash
bash claude-status/install-hooks.sh
```

---

**问题 3：提示端口被占用**

```bash
lsof -ti:4242 | xargs kill -9
bash start.sh
```

---

## 想放到副屏上？

把浏览器窗口拖到副屏，全屏显示 `http://localhost:4242` 就行。

如果你的副屏是通过采集卡接的，分辨率不标准，参考 README 里的 **BetterDisplay 虚拟屏** 章节创建一个虚拟显示器来解决。
