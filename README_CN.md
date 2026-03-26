# SpaceLauncher

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[English](README.md) | **简体中文**

<p align="center">
  <img src="Resources/screenshot.png" alt="SpaceLauncher 截图" width="600">
</p>

> 🚀 **macOS 上最快启动应用的方式** — 按住空格，按一个键，完成。

一款轻量级 macOS 应用启动器，使用 **空格键作为修饰键**。不再需要 `Cmd+空格` 或伸手去拿鼠标 — 只要按住空格，轻按一个键就能瞬间启动任何应用。

## ✨ 核心特色

| 功能 | 说明 |
|------|------|
| 🎯 **空格作为修饰键** | 按住空格 150ms 激活，短按仍然输入空格 |
| ⚡ **瞬间启动** | 无 UI 延迟，无需搜索 — 肌肉记忆即可 |
| 🔄 **连续切换** | 保持按住空格，可连续按多个键快速切换应用 |
| 💡 **可视化提示** | 精美的浮窗面板，一目了然显示所有快捷键 |
| ⚙️ **热重载配置** | 编辑 YAML 配置文件，更改即时生效 |
| 🔈 **音效反馈** | 微妙的提示音确认启动成功 |
| 🌙 **仅菜单栏** | 无 Dock 图标，占用极小 |

## 🎬 演示

```
┌─────────────────────────────────────────┐
│                                         │
│   [空格] ──按住 150ms──> 🎯 激活        │
│                                         │
│         ┌─────────────────┐             │
│         │  🎯 SpaceLauncher │           │
│         ├─────────────────┤             │
│         │  d  📱 钉钉      │             │
│         │  w  💬 微信      │             │
│         │  c  🌐 Chrome    │             │
│         │  v  💻 VS Code   │             │
│         │  t  ⬛ 终端      │             │
│         │  f  📁 Finder    │             │
│         └─────────────────┘             │
│                                         │
│   按 'v' ──> VS Code 启动! ✨           │
│   按 'c' ──> Chrome 启动! ✨            │
│   (保持按住空格，继续切换其他应用!)     │
│                                         │
└─────────────────────────────────────────┘
```

## 🚀 安装

### 下载发布版本

从 [Releases](https://github.com/yue1132/SpaceLauncher/releases) 下载最新版本。

### 从源码构建

```bash
git clone https://github.com/yue1132/SpaceLauncher.git
cd SpaceLauncher
./build.sh
```

构建完成后，应用位于 `build/SpaceLauncher.app`。

### 安装

```bash
cp -r build/SpaceLauncher.app /Applications/
```

## 📖 使用方法

### 快速上手

1. 启动 SpaceLauncher
2. **授予辅助功能权限**（首次运行会自动提示）
3. 按住空格约 150ms，直到出现提示面板
4. 保持按住空格，按下配置的键启动应用
5. 松开空格，面板消失

### 💡 使用技巧

| 技巧 | 说明 |
|------|------|
| 🔄 **连续切换** | 保持按住空格，连续按多个键可快速在应用间切换 |
| ⏸️ **暂停功能** | 玩游戏时点击菜单栏图标 →「暂停运行」 |
| 🔄 **重载配置** | 修改配置后，右键菜单栏图标 →「重新加载配置」 |
| 🔐 **开机自启** | 从菜单栏启用「开机自启」 |

## ⚙️ 配置

配置文件路径：`~/.spacelauncher/config.yaml`

首次运行会自动创建默认配置。

### 默认快捷键

| 按键 | 应用 |
|------|------|
| `d` | 钉钉 |
| `w` | 微信 |
| `c` | Chrome |
| `v` | VS Code |
| `t` | 终端 |
| `f` | Finder |

### 完整配置示例

```yaml
settings:
  hold_threshold_ms: 150  # 按住空格激活的阈值时间(毫秒)

shortcuts:
  # 💬 社交通讯
  d: /Applications/DingTalk.app
  w: /Applications/WeChat.app

  # 💻 开发工具
  v: /Applications/Visual Studio Code.app
  t: /System/Applications/Terminal.app

  # 🌐 浏览器与工具
  c: /Applications/Google Chrome.app
  f: /System/Applications/Finder.app
  s: /Applications/Safari.app

  # 🎨 创意工具
  x: /Applications/Xcode.app
  p: /Applications/Photoshop.app
```

### 热重载

编辑配置文件后，按 `Cmd+R`（或菜单 → 重新加载配置），更改即时生效，无需重启应用。

## ❓ 常见问题

### 为什么需要辅助功能权限？

SpaceLauncher 需要监听全局键盘事件来检测空格键，这需要辅助功能权限。应用只在空格键被按下时监听键盘事件，不会记录或存储任何按键信息。

### 空格键不生效怎么办？

1. 检查是否已授予辅助功能权限（菜单栏图标显示 ⚠️ 表示未授权）
2. 尝试从菜单栏暂停再恢复
3. 检查是否有其他应用拦截了空格键

### 与 Spotlight/Alfred 有什么不同？

| 特性 | SpaceLauncher | Spotlight/Alfred |
|------|---------------|------------------|
| 触发方式 | 按住空格 (150ms) | Cmd+空格 |
| 输入方式 | 单个按键 | 输入应用名 |
| 速度 | 瞬间启动 | 取决于输入速度 |
| 学习曲线 | 肌肉记忆 | 搜索式 |
| 配置 | 简单 YAML | 复杂工作流 |

SpaceLauncher 专为**速度**设计 — 无需输入，无需搜索，按住即按。适合希望用肌肉记忆快速启动常用应用的用户。

### 可以用其他键代替空格吗？

目前不支持。选择空格键的原因：
- 按键够大，容易按住
- 很少作为其他应用的修饰键
- 短按仍然正常输入空格

## 🔮 开发计划

- [ ] 自定义修饰键支持
- [ ] 提示面板显示应用图标
- [ ] 多键组合快捷键
- [ ] URL Scheme 支持
- [ ] GitHub 自动更新

## 🛠️ 开发

### 环境要求

- macOS 13.0+
- Xcode 15.0+ (或 Swift 5.9+)
- Yams 依赖（SPM 自动获取）

### 项目结构

```
SpaceLauncher/
├── Package.swift
├── build.sh
├── Resources/
│   ├── Info.plist
│   └── SpaceLauncher.entitlements
└── Sources/SpaceLauncher/
    ├── SpaceLauncherApp.swift      # 应用入口，菜单栏
    ├── Models/
    │   └── Config.swift            # 配置模型
    ├── Services/
    │   ├── KeyboardMonitor.swift   # 全局键盘监听
    │   ├── AppLauncher.swift       # 应用启动逻辑
    │   └── ConfigManager.swift     # 配置加载与热重载
    └── Views/
        └── ShortcutHintView.swift  # 浮动提示面板
```

### 构建与运行

```bash
swift build
swift run SpaceLauncher
```

## 📄 许可证

[MIT 许可证](LICENSE) — 可自由使用、修改和分发。