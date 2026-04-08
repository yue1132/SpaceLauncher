# SpaceLauncher

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**English** | [简体中文](README_CN.md)

<p align="center">
  <img src="Resources/screenshot.png" alt="SpaceLauncher Screenshot" width="600">
</p>

> 🚀 **The fastest way to launch apps on macOS** — Hold a key, press a key, done.

A lightweight macOS app launcher that turns a **key of your choice into a modifier**. No more `Cmd+Space` or reaching for the mouse — just hold your trigger key and tap a key to instantly launch any app. Supports **Space**, **Caps Lock**, and **ESC** as trigger keys.

## ✨ Highlights

| Feature | Description |
|---------|-------------|
| 🎯 **Configurable Trigger Key** | Choose Space, Caps Lock, or ESC as your trigger — hold to activate |
| ⚡ **Instant Launch** | No UI lag, no search needed — muscle memory takes over |
| 🔄 **Continuous Switch** | Keep holding trigger key to switch between multiple apps rapidly |
| 💡 **Visual Hints** | Beautiful floating panel shows all your shortcuts at a glance |
| ⚙️ **Hot-Reload Config** | Edit YAML config file, changes apply instantly |
| 🔈 **Audio Feedback** | Subtle sound confirms your launch |
| 🌙 **Menu Bar Only** | No Dock icon, minimal footprint |

## 🎬 Demo

```
┌─────────────────────────────────────────┐
│                                         │
│   [Space] ──hold 150ms──> 🎯 Activate   │
│                                         │
│         ┌─────────────────┐             │
│         │  🎯 SpaceLauncher │           │
│         ├─────────────────┤             │
│         │  d  📱 DingTalk  │             │
│         │  w  💬 WeChat    │             │
│         │  c  🌐 Chrome    │             │
│         │  v  💻 VS Code   │             │
│         │  t  ⬛ Terminal  │             │
│         │  f  📁 Finder    │             │
│         └─────────────────┘             │
│                                         │
│   Press 'v' ──> VS Code launches! ✨    │
│   Press 'c' ──> Chrome launches! ✨     │
│   (Trigger still held, keep switching!) │
│                                         │
└─────────────────────────────────────────┘
```

## 🚀 Installation

### Download Release

Download the latest release from [Releases](https://github.com/yue1132/SpaceLauncher/releases).

### Build from Source

```bash
git clone https://github.com/yue1132/SpaceLauncher.git
cd SpaceLauncher
./build.sh
```

The built app will be at `build/SpaceLauncher.app`.

### Install

```bash
cp -r build/SpaceLauncher.app /Applications/
```

## 📖 Usage

### Quick Start

1. Launch SpaceLauncher
2. **Grant Accessibility Permission** (follow the guided prompt)
3. Hold your trigger key (Space by default) for ~150ms until the hint panel appears
4. While holding, press a key to launch the app
5. Release the trigger key to dismiss

### Pro Tips

| Tip | Description |
|-----|-------------|
| 🔄 **Continuous Switch** | Keep holding trigger key and press multiple keys to switch between apps rapidly |
| ⏸️ **Pause Function** | Click menu bar icon → "Pause" when you need the trigger key to behave normally (gaming, etc.) |
| 🔄 **Reload Config** | Right-click menu bar icon → "Reload Config" after editing the config file |
| 🔐 **Auto-Start** | Enable "Launch at Login" from the menu bar |
| 🎹 **Change Trigger Key** | Set `trigger_key` in config to `space`, `caps_lock`, or `esc` |

## ⚙️ Configuration

Config file: `~/.spacelauncher/config.yaml`

Created automatically on first run with sensible defaults.

### Default Shortcuts

| Key | App |
|-----|-----|
| `d` | DingTalk |
| `w` | WeChat |
| `c` | Chrome |
| `v` | VS Code |
| `t` | Terminal |
| `f` | Finder |

### Full Configuration Example

```yaml
settings:
  hold_threshold_ms: 150  # Time to hold trigger key before activating
  trigger_key: space      # Trigger key: space, caps_lock, or esc

shortcuts:
  # 💬 Communication
  d: /Applications/DingTalk.app
  w: /Applications/WeChat.app

  # 💻 Development
  v: /Applications/Visual Studio Code.app
  t: /System/Applications/Terminal.app

  # 🌐 Browser & Tools
  c: /Applications/Google Chrome.app
  f: /System/Applications/Finder.app
  s: /Applications/Safari.app

  # 🎨 Creative
  x: /Applications/Xcode.app
  p: /Applications/Photoshop.app
```

### Hot Reload

Edit your config file and press `Cmd+R` (or menu → Reload Config) — changes apply instantly without restart.

## ❓ FAQ

### Why does it need Accessibility permission?

SpaceLauncher monitors global keyboard events to detect the trigger key. This requires Accessibility permission. The app only monitors keyboard events when the trigger key is pressed — no keystrokes are logged or stored.

### The trigger key isn't working

1. Check if Accessibility permission is granted (menu bar icon shows ⚠️ if not)
2. Try pausing and resuming from the menu bar
3. Check if another app is intercepting the trigger key

### How is this different from Spotlight/Alfred?

| Feature | SpaceLauncher | Spotlight/Alfred |
|---------|---------------|------------------|
| Trigger | Hold trigger key (150ms) | Cmd+Space |
| Input | Single key | Type app name |
| Speed | Instant | Depends on typing |
| Learning curve | Muscle memory | Search-based |
| Setup | Simple YAML | Complex workflows |

SpaceLauncher is designed for **speed** — no typing, no searching, just hold and tap.

### Can I use a different key instead of Space?

Yes! Set the `trigger_key` option in your config file. Available options:

| Key | Config Value | Notes |
|-----|-------------|-------|
| Space | `space` | Default. Short press still types space |
| Caps Lock | `caps_lock` | Great for keyboard enthusiasts |
| ESC | `esc` | Less commonly used, fewer conflicts |

## 🔮 Roadmap

- [x] Custom trigger key support (Space, Caps Lock, ESC)
- [ ] App icon in hint panel
- [ ] Multi-key shortcuts
- [ ] URL scheme support
- [ ] GitHub auto-update

## 🛠️ Development

### Requirements

- macOS 13.0+
- Xcode 15.0+ (or Swift 5.9+)
- Yams dependency (auto-fetched by SPM)

### Project Structure

```
SpaceLauncher/
├── Package.swift
├── build.sh
├── Resources/
│   ├── Info.plist
│   └── SpaceLauncher.entitlements
└── Sources/SpaceLauncher/
    ├── SpaceLauncherApp.swift      # App entry, menu bar
    ├── Models/
    │   └── Config.swift            # Config model
    ├── Services/
    │   ├── KeyboardMonitor.swift   # Global keyboard monitoring
    │   ├── AppLauncher.swift       # App launching logic
    │   └── ConfigManager.swift     # Config loading & hot-reload
    └── Views/
        └── ShortcutHintView.swift  # Floating hint panel
```

### Build & Run

```bash
swift build
swift run SpaceLauncher
```

## 📄 License

[MIT License](LICENSE) — feel free to use, modify, and distribute.