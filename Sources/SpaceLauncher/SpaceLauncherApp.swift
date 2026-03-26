import SwiftUI
import ServiceManagement

@main
struct SpaceLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var keyboardMonitor: KeyboardMonitor?
    private var configManager: ConfigManager?
    private var hintWindow: NSWindow?
    private var hintViewController: HintViewController?
    private var permissionAlertShown = false
    private var isPaused = false  // 全局暂停状态

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏Dock图标，仅显示菜单栏
        NSApp.setActivationPolicy(.accessory)

        setupMenuBar()

        // 检查辅助功能权限
        checkAccessibilityPermission()

        setupConfigManager()
        setupKeyboardMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardMonitor?.stop()
    }

    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()

        if !trusted && !permissionAlertShown {
            permissionAlertShown = true

            // 显示权限请求对话框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let alert = NSAlert()
                alert.messageText = "SpaceLauncher 需要辅助功能权限"
                alert.informativeText = "请在系统设置中授予 SpaceLauncher 辅助功能权限，以便监听键盘事件。\n\n点击\"打开系统设置\"后，在列表中添加 SpaceLauncher。"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "稍后设置")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // 打开系统设置的辅助功能页面
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        updateMenuBarIcon()

        let menu = NSMenu()

        // 状态显示
        let trusted = AXIsProcessTrusted()
        let statusTitle = trusted ? "✅ SpaceLauncher 运行中" : "⚠️ 需要授权"
        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        if !trusted {
            menu.addItem(NSMenuItem(title: "授权辅助功能...", action: #selector(requestPermission), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(NSMenuItem(title: "打开配置文件...", action: #selector(openConfig), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "重新加载配置", action: #selector(reloadConfig), keyEquivalent: "r"))

        // 开机自启
        let launchAtLoginItem = NSMenuItem(title: "开机自启", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = (configManager?.config.settings.launchAtLogin ?? false) ? .on : .off
        menu.addItem(launchAtLoginItem)

        // 暂停/恢复
        let pauseItem = NSMenuItem(title: isPaused ? "恢复运行" : "暂停运行", action: #selector(togglePause), keyEquivalent: "p")
        menu.addItem(pauseItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "退出 SpaceLauncher", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let trusted = AXIsProcessTrusted()
            let imageName = trusted ? "keyboard" : "exclamationmark.triangle"
            button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "SpaceLauncher")
            button.image?.isTemplate = true
            button.toolTip = trusted ? "SpaceLauncher - 按住空格启动应用" : "SpaceLauncher - 需要辅助功能权限"
        }
    }

    private func setupConfigManager() {
        configManager = ConfigManager()
        configManager?.loadConfig()
    }

    private func setupKeyboardMonitor() {
        keyboardMonitor = KeyboardMonitor(
            configManager: configManager!,
            onWaitingMode: { [weak self] in
                DispatchQueue.main.async {
                    self?.showHintWindow()
                }
            },
            onShortcutTriggered: { [weak self] shortcut in
                DispatchQueue.main.async {
                    // 不隐藏窗口，让用户可以继续选择其他应用
                    self?.launchApp(for: shortcut)
                }
            },
            onModeEnded: { [weak self] in
                DispatchQueue.main.async {
                    self?.hideHintWindow()
                }
            }
        )
        keyboardMonitor?.start()

        // 更新菜单栏图标
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateMenuBarIcon()
            self.setupMenuBar()
        }
    }

    private func showHintWindow() {
        guard let shortcuts = configManager?.config.shortcuts, !shortcuts.isEmpty else { return }

        if hintWindow == nil {
            let viewController = HintViewController()
            hintViewController = viewController
            hintWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 280, height: 400),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            hintWindow?.contentView = viewController.view
            hintWindow?.level = .screenSaver
            hintWindow?.isOpaque = false
            hintWindow?.backgroundColor = .clear
            hintWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            hintWindow?.ignoresMouseEvents = true
        }

        hintViewController?.updateShortcuts(shortcuts)
        hintWindow?.center()
        hintWindow?.makeKeyAndOrderFront(nil)
    }

    private func hideHintWindow() {
        hintWindow?.orderOut(nil)
    }

    private func launchApp(for shortcut: Shortcut) {
        // 播放音效反馈
        NSSound(named: "Funk")?.play()
        AppLauncher.shared.launch(appPath: shortcut.appPath, key: shortcut.key)
    }

    @objc private func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    @objc private func openConfig() {
        configManager?.openConfigFile()
    }

    @objc private func reloadConfig() {
        configManager?.loadConfig()
        if let shortcuts = configManager?.config.shortcuts {
            print("Config reloaded: \(shortcuts.count) shortcuts")
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newValue = sender.state == .off
        sender.state = newValue ? .on : .off
        configManager?.setLaunchAtLogin(newValue)

        do {
            if newValue {
                try SMAppService.mainApp.register()
                print("✅ Launch at login enabled")
            } else {
                try SMAppService.mainApp.unregister()
                print("✅ Launch at login disabled")
            }
            configManager?.saveSettings()
        } catch {
            print("❌ Failed to toggle launch at login: \(error)")
        }
    }

    @objc private func togglePause(_ sender: NSMenuItem) {
        isPaused.toggle()
        sender.title = isPaused ? "恢复运行" : "暂停运行"
        keyboardMonitor?.setPaused(isPaused)

        // 更新菜单栏图标
        if let button = statusItem?.button {
            let imageName = isPaused ? "pause.circle" : "keyboard"
            button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "SpaceLauncher")
            button.toolTip = isPaused ? "SpaceLauncher - 已暂停" : "SpaceLauncher - 按住空格启动应用"
        }

        print(isPaused ? "⏸️ SpaceLauncher paused" : "▶️ SpaceLauncher resumed")
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}