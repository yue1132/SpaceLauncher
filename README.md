# SpaceLauncher

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**English** | [简体中文](README_CN.md)

<p align="center">
  <img src="Resources/screenshot.png" alt="SpaceLauncher Screenshot" width="600">
</p>

> 🚀 **The fastest way to launch apps on macOS** — Hold Space, press a key, done.

A lightweight macOS app launcher that uses the **Space key as a modifier**. No more `Cmd+Space` or reaching for the mouse — just hold Space and tap a key to instantly launch any app.

## ✨ Highlights

| Feature | Description |
|---------|-------------|
| 🎯 **Space as Modifier** | Hold Space for 150ms to activate — short press still types space |
| ⚡ **Instant Launch** | No UI lag, no search needed — muscle memory takes over |
| 🔄 **Continuous Switch** | Keep holding Space to switch between multiple apps rapidly |
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
│   (Space still held, keep switching!)  │
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
2. **Grant Accessibility Permission** (prompted automatically)
3. Hold Space for ~150ms until the hint panel appears
4. While holding Space, press a key to launch the app
5. Release Space to dismiss

### Pro Tips

| Tip | Description |
|-----|-------------|
| 🔄 **Continuous Switch** | Keep holding Space and press multiple keys to switch between apps rapidly |
| ⏸️ **Pause Function** | Click menu bar icon → "Pause" when you need Space to behave normally (gaming, etc.) |
| 🔄 **Reload Config** | Right-click menu bar icon → "Reload Config" after editing the config file |
| 🔐 **Auto-Start** | Enable "Launch at Login" from the menu bar |

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
  hold_threshold_ms: 150  # Time to hold Space before activating

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

SpaceLauncher monitors global keyboard events to detect the Space key. This requires Accessibility permission. The app only monitors keyboard events when Space is pressed — no keystrokes are logged or stored.

### Space isn't working as expected

1. Check if Accessibility permission is granted (menu bar icon shows ⚠️ if not)
2. Try pausing and resuming from the menu bar
3. Check if another app is intercepting Space key

### How is this different from Spotlight/Alfred?

| Feature | SpaceLauncher | Spotlight/Alfred |
|---------|---------------|------------------|
| Trigger | Hold Space (150ms) | Cmd+Space |
| Input | Single key | Type app name |
| Speed | Instant | Depends on typing |
| Learning curve | Muscle memory | Search-based |
| Setup | Simple YAML | Complex workflows |

SpaceLauncher is designed for **speed** — no typing, no searching, just hold and tap.

### Can I use a different key instead of Space?

Not currently. Space was chosen because:
- It's large and easy to hold
- Rarely used as a modifier in other apps
- Short press still types space normally

## 🔮 Roadmap

- [ ] Custom modifier key support
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