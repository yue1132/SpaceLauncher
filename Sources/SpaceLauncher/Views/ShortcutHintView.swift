import AppKit
import SwiftUI

class HintViewController: NSViewController {
    private var shortcuts: [Shortcut] = []
    private var hostingView: NSHostingView<HintView>?

    override func loadView() {
        let hostingView = NSHostingView(rootView: HintView(shortcuts: []))
        self.hostingView = hostingView
        view = hostingView
    }

    func updateShortcuts(_ shortcutsDict: [String: String]) {
        self.shortcuts = shortcutsDict.map { Shortcut(key: $0.key, appPath: $0.value) }
            .sorted { $0.key < $1.key }

        DispatchQueue.main.async { [weak self] in
            self?.hostingView?.rootView = HintView(shortcuts: self?.shortcuts ?? [])
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.makeKey()
    }
}

struct HintView: View {
    let shortcuts: [Shortcut]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                Text("SpaceLauncher")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("按住 Space + 键")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 8)

            // 列表式布局
            VStack(alignment: .leading, spacing: 2) {
                ForEach(shortcuts, id: \.key) { shortcut in
                    ShortcutRow(shortcut: shortcut)
                }
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                .shadow(
                    color: colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.12),
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.08),
                    lineWidth: 0.5
                )
        )
    }
}

struct ShortcutRow: View {
    let shortcut: Shortcut
    @State private var appIcon: NSImage?
    @State private var iconLoaded = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            // 左侧：快捷键
            Text(shortcut.key.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(colorScheme == .dark
                            ? Color.white.opacity(0.15)
                            : Color.black.opacity(0.06))
                )

            // 中间：应用图标
            ZStack {
                if let icon = appIcon, iconLoaded {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else if iconLoaded {
                    Text(String(shortcut.appName.prefix(1)).uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                } else {
                    Color.clear
                        .frame(width: 20, height: 20)
                }
            }

            // 右侧：应用名称
            Text(shortcut.appName)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onAppear {
            loadAppIcon()
        }
    }

    private func loadAppIcon() {
        let path = shortcut.appPath.trimmingCharacters(in: .whitespacesAndNewlines)

        // 先检查缓存
        if let cachedIcon = AppIconCache.shared.icon(for: path) {
            self.appIcon = cachedIcon
            self.iconLoaded = true
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var effectivePath = path

            if !FileManager.default.fileExists(atPath: effectivePath) {
                effectivePath = self.searchForApp(appName: self.shortcut.appName) ?? path
            }

            let icon = NSWorkspace.shared.icon(forFile: effectivePath)
            let isValidIcon = icon.isValid && icon.size.width > 0

            DispatchQueue.main.async {
                if isValidIcon {
                    icon.size = NSSize(width: 20, height: 20)
                    self.appIcon = icon
                    // 存入缓存
                    AppIconCache.shared.setIcon(icon, for: path)
                }
                self.iconLoaded = true
            }
        }
    }

    private func searchForApp(appName: String) -> String? {
        let searchPaths = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
            "/System/Applications",
            "/System/Library/CoreServices"
        ]

        for searchPath in searchPaths {
            let appPath = searchPath + "/\(appName).app"
            if FileManager.default.fileExists(atPath: appPath) {
                return appPath
            }
        }
        return nil
    }
}

extension NSImage {
    var isValid: Bool {
        return tiffRepresentation != nil
    }
}

// 图标缓存
class AppIconCache {
    static let shared = AppIconCache()
    private var cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 50
    }

    func icon(for path: String) -> NSImage? {
        let key = path as NSString
        return cache.object(forKey: key)
    }

    func setIcon(_ icon: NSImage, for path: String) {
        let key = path as NSString
        cache.setObject(icon, forKey: key)
    }
}

#Preview {
    HintView(shortcuts: [
        Shortcut(key: "d", appPath: "/Applications/DingTalk.app"),
        Shortcut(key: "w", appPath: "/Applications/WeChat.app"),
        Shortcut(key: "c", appPath: "/Applications/Google Chrome.app"),
        Shortcut(key: "v", appPath: "/Applications/Visual Studio Code.app"),
        Shortcut(key: "t", appPath: "/System/Applications/Terminal.app"),
        Shortcut(key: "f", appPath: "/System/Library/CoreServices/Finder.app"),
        Shortcut(key: "q", appPath: "/Applications/QQ.app"),
        Shortcut(key: "z", appPath: "/Applications/Zen.app")
    ])
    .frame(width: 260)
}