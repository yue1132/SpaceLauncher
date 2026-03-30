import Foundation
import AppKit
import Carbon

class AppLauncher {
    static let shared = AppLauncher()

    private let workspace = NSWorkspace.shared
    private var lastActivatedBundleId: String?
    private var lastActivatedKey: String?
    private var currentWindowIndex: [String: Int] = [:]

    private init() {}

    func launch(appPath: String, key: String) {
        let trimmedPath = appPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(fileURLWithPath: trimmedPath)

        guard FileManager.default.fileExists(atPath: trimmedPath) else {
            print("❌ App not found: \(trimmedPath)")
            searchAndLaunch(appName: url.deletingPathExtension().lastPathComponent)
            return
        }

        let bundleIdentifier = getBundleIdentifier(for: url)
        let currentFrontmost = workspace.frontmostApplication?.bundleIdentifier

        let shouldSwitchWindow = (lastActivatedKey == key
            && lastActivatedBundleId == bundleIdentifier
            && currentFrontmost == bundleIdentifier)

        if shouldSwitchWindow {
            switchToNextWindow(bundleIdentifier: bundleIdentifier, appPath: trimmedPath)
        } else {
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)

            if let runningApp = runningApps.first {
                activateApp(runningApp, url: url)
            } else {
                launchNewApp(url: url)
            }

            lastActivatedBundleId = bundleIdentifier
            lastActivatedKey = key
            currentWindowIndex[bundleIdentifier] = 0
        }
    }

    private func switchToNextWindow(bundleIdentifier: String, appPath: String) {
        print("🔄 Switching window for: \(bundleIdentifier)")

        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            print("❌ App not running")
            return
        }

        // 获取当前 Space 的窗口（通过 AX API）- 这是原来能工作的方法
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            print("⚠️ No windows found via AX API")
            // 如果 AX API 没找到窗口，尝试用 workspace.open 激活
            workspace.open(URL(fileURLWithPath: appPath))
            return
        }

        print("📋 Found \(windows.count) AX windows in current space")

        // 检查是否有其他 Space 的全屏窗口
        let allWindowsInfo = getAllWindowsInfo(for: bundleIdentifier)
        let hasFullscreenWindow = allWindowsInfo.contains { $0.isFullscreen }
        print("📋 Total windows across spaces: \(allWindowsInfo.count), fullscreen: \(hasFullscreenWindow)")

        // 查找当前焦点窗口
        var focusedIndex = -1
        for (index, window) in windows.enumerated() {
            var isFocused: CFTypeRef?
            let focusResult = AXUIElementCopyAttributeValue(window, kAXFocusedAttribute as CFString, &isFocused)
            if focusResult == .success && (isFocused as? Bool) == true {
                focusedIndex = index
                break
            }
        }

        print("📋 Focused window index: \(focusedIndex)")

        // 如果找不到焦点窗口，使用记录的索引
        if focusedIndex == -1 {
            focusedIndex = currentWindowIndex[bundleIdentifier] ?? 0
        }

        // 计算下一个窗口索引
        let nextIndex = (focusedIndex + 1) % windows.count
        currentWindowIndex[bundleIdentifier] = nextIndex

        let nextWindow = windows[nextIndex]

        // 获取窗口标题
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(nextWindow, kAXTitleAttribute as CFString, &titleRef)
        let title = (titleRef as? String) ?? "Untitled"

        print("🎯 Activating window \(nextIndex + 1)/\(windows.count): \(title)")

        // 使用 AX API 激活窗口（原来能工作的方法）
        AXUIElementPerformAction(nextWindow, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(nextWindow, kAXMainAttribute as CFString, true as CFTypeRef)
        AXUIElementSetAttributeValue(nextWindow, kAXFocusedAttribute as CFString, true as CFTypeRef)
        app.activate(options: [.activateIgnoringOtherApps])

        // 如果有全屏窗口且当前切换完当前 Space 的窗口，尝试切换到全屏 Space
        if hasFullscreenWindow && nextIndex == windows.count - 1 {
            print("🖥️ Try switching to fullscreen space...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 使用 Cmd+` 窗口切换快捷键，这可以切换到全屏窗口
                self.sendWindowSwitchShortcut()
            }
        }

        print("✅ Switched to: \(title)")
    }

    /// 发送 Cmd+` 窗口切换快捷键
    private func sendWindowSwitchShortcut() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Cmd down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = CGEventFlags.maskCommand
        cmdDown?.post(tap: .cgSessionEventTap)

        // ` (grave) down - keycode 0x32
        let graveDown = CGEvent(keyboardEventSource: source, virtualKey: 0x32, keyDown: true)
        graveDown?.flags = CGEventFlags.maskCommand
        graveDown?.post(tap: .cgSessionEventTap)

        // ` up
        let graveUp = CGEvent(keyboardEventSource: source, virtualKey: 0x32, keyDown: false)
        graveUp?.flags = CGEventFlags.maskCommand
        graveUp?.post(tap: .cgSessionEventTap)

        // Cmd up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.flags = CGEventFlags.maskCommand
        cmdUp?.post(tap: .cgSessionEventTap)

        print("⌨️ Sent Cmd+` window switch shortcut")
    }

    /// 获取所有窗口信息（包括跨 Space）
    private func getAllWindowsInfo(for bundleIdentifier: String) -> [(windowID: Int, isFullscreen: Bool, title: String)] {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var windows: [(windowID: Int, isFullscreen: Bool, title: String)] = []

        for windowInfo in windowList {
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int,
                  let windowID = windowInfo[kCGWindowNumber as String] as? Int else {
                continue
            }

            guard let runningApp = NSRunningApplication(processIdentifier: pid_t(ownerPID)),
                  runningApp.bundleIdentifier == bundleIdentifier else {
                continue
            }

            var isFullscreen = false
            if let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
               let width = bounds["Width"] as? CGFloat,
               let height = bounds["Height"] as? CGFloat {
                if let screen = NSScreen.main {
                    isFullscreen = width >= screen.frame.width * 0.9 && height >= screen.frame.height * 0.9
                }
            }

            let title = windowInfo[kCGWindowName as String] as? String ?? ""

            // 过滤空标题的非全屏窗口
            if title.isEmpty && !isFullscreen {
                continue
            }

            windows.append((windowID: windowID, isFullscreen: isFullscreen, title: title))
        }

        return windows
    }

    private func activateApp(_ app: NSRunningApplication, url: URL) {
        workspace.open(url)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            _ = app.activate(options: [.activateIgnoringOtherApps])
            print("✅ Activated: \(url.lastPathComponent)")
        }
    }

    private func launchNewApp(url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        workspace.openApplication(at: url, configuration: config) { app, error in
            if let error = error {
                print("❌ Failed to launch: \(error)")
            } else {
                print("✅ Launched: \(url.lastPathComponent)")
            }
        }
    }

    private func searchAndLaunch(appName: String) {
        let searchPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
            "/System/Applications",
            "/System/Library/CoreServices"
        ]

        for searchPath in searchPaths {
            let appPath = searchPath + "/\(appName).app"
            if FileManager.default.fileExists(atPath: appPath) {
                print("🔍 Found at: \(appPath)")
                launch(appPath: appPath, key: "")
                return
            }
        }

        print("❌ App not found: \(appName)")
    }

    private func getBundleIdentifier(for url: URL) -> String {
        if let bundle = Bundle(url: url) {
            return bundle.bundleIdentifier ?? ""
        }
        return ""
    }
}