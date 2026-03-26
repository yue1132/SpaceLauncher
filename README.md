# SpaceLauncher

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**English** | [中文](#中文说明)

A macOS快捷键启动器 that uses the Space key as a modifier. Hold Space, then press another key to quickly launch applications.

## Features

- **Space as Modifier**: Hold Space for 150ms to enter waiting mode and show shortcut hints
- **Visual Shortcut Hints**: Displays a floating panel with all configured shortcuts and app icons
- **YAML Configuration**: Easy-to-edit config file with hot-reload support
- **Menu Bar App**: Lightweight menu bar icon with quick actions

## Installation

### Build from Source

```bash
git clone https://github.com/yourusername/SpaceLauncher.git
cd SpaceLauncher
./build.sh
```

The built app will be at `build/SpaceLauncher.app`.

### Install to Applications

```bash
cp -r build/SpaceLauncher.app /Applications/
```

## Usage

1. Launch SpaceLauncher
2. **Grant Accessibility Permission** (System Settings → Privacy & Security → Accessibility → Add SpaceLauncher)
3. Hold Space for ~150ms, a shortcut hint panel will appear
4. While holding Space, press a configured key to launch the app
5. Short press Space works normally (inputs a space character)

## Configuration

Config file path: `~/.spacelauncher/config.yaml`

A default config will be created on first run.

### Default Shortcuts

| Key | Application |
|-----|-------------|
| `d` | DingTalk |
| `w` | WeChat |
| `c` | Chrome |
| `v` | VS Code |
| `t` | Terminal |
| `f` | Finder |

### Example Config

```yaml
settings:
  hold_threshold_ms: 150  # Hold threshold in milliseconds

shortcuts:
  # Communication
  d: /Applications/DingTalk.app
  w: /Applications/WeChat.app

  # Development
  v: /Applications/Visual Studio Code.app
  t: /System/Applications/Terminal.app

  # Browser & Tools
  c: /Applications/Google Chrome.app
  f: /System/Applications/Finder.app
```

## Requirements

- macOS 13.0 or later
- Accessibility permission (for global keyboard monitoring)

## Project Structure

```
SpaceLauncher/
├── Package.swift
├── build.sh                   # Build script
├── Resources/
│   ├── Info.plist
│   └── SpaceLauncher.entitlements
└── Sources/SpaceLauncher/
    ├── SpaceLauncherApp.swift      # App entry
    ├── Models/
    │   └── Config.swift            # Config model
    ├── Services/
    │   ├── KeyboardMonitor.swift   # Keyboard monitoring
    │   ├── AppLauncher.swift       # App launching
    │   └── ConfigManager.swift     # Config management
    └── Views/
        └── ShortcutHintView.swift  # Hint overlay
```

## License

[MIT License](LICENSE)

---

## 中文说明

一款 Mac 快捷键启动器软件，按住 Space 键作为修饰键，再按其他按键快速启动应用程序。

### 功能特性

- **Space 修饰键**: 按住 Space 超过 150ms 进入等待模式，显示快捷键提示浮窗
- **快捷键提示浮窗**: 显示所有配置的快捷键和应用图标
- **配置文件**: YAML 格式，支持热重载
- **菜单栏图标**: 显示运行状态，右键菜单操作

### 菜单栏操作

- 点击菜单栏图标可以：
  - 打开配置文件
  - 重新加载配置
  - 退出应用

### 权限要求

- **辅助功能权限**: 用于监听全局键盘事件