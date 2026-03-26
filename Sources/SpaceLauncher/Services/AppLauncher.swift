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
            switchToNextWindow(bundleIdentifier: bundleIdentifier)
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

    private func switchToNextWindow(bundleIdentifier: String) {
        print("🔄 Switching window for: \(bundleIdentifier)")

        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            print("❌ App not running")
            return
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
            print("⚠️ No windows found")
            return
        }

        print("📋 Found \(windows.count) windows")

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

        // 如果没有找到焦点窗口，使用记录的索引
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

        // 尝试激活窗口 - 多种方法
        print("🎯 Activating window \(nextIndex + 1)/\(windows.count): \(title)")

        // 方法1: Raise
        AXUIElementPerformAction(nextWindow, kAXRaiseAction as CFString)

        // 方法2: 设置为主窗口
        AXUIElementSetAttributeValue(nextWindow, kAXMainAttribute as CFString, true as CFTypeRef)

        // 方法3: 设置焦点
        AXUIElementSetAttributeValue(nextWindow, kAXFocusedAttribute as CFString, true as CFTypeRef)

        // 方法4: 确保应用在最前
        app.activate(options: [.activateIgnoringOtherApps])

        print("✅ Switched to: \(title)")
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