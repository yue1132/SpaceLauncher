import Foundation
import AppKit
import Yams

class ConfigManager {
    private let configPath: URL
    private let fileManager = FileManager.default
    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?

    private(set) var config: Config = Config()
    var onConfigChanged: (() -> Void)?

    init(configPath: URL? = nil) {
        if let path = configPath {
            self.configPath = path
        } else {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            self.configPath = homeDir.appendingPathComponent(".spacelauncher/config.yaml")
        }

        createDefaultConfigIfNotExists()
    }

    deinit {
        source?.cancel()
        fileHandle?.closeFile()
    }

    func loadConfig() {
        print("📂 Loading config from: \(configPath.path)")

        do {
            let data = try Data(contentsOf: configPath)
            let yamlString = String(data: data, encoding: .utf8) ?? ""
            print("📄 Config file size: \(yamlString.count) chars")

            // 尝试解析配置
            let decoder = YAMLDecoder()
            var newConfig = try decoder.decode(Config.self, from: yamlString)
            print("✅ YAML parsed successfully")

            // 清理路径中的空格
            var cleanedShortcuts: [String: String] = [:]
            for (key, path) in newConfig.shortcuts {
                let cleanedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
                cleanedShortcuts[key] = cleanedPath
            }
            newConfig.shortcuts = cleanedShortcuts

            // 验证配置
            var validShortcuts: [String: String] = [:]
            for (key, path) in newConfig.shortcuts {
                var effectivePath = path

                // 如果路径不存在，尝试搜索应用（模糊匹配）
                if !fileManager.fileExists(atPath: path) {
                    // 先尝试作为应用名称搜索
                    let appName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                    if let foundPath = searchForApp(appName: appName) {
                        effectivePath = foundPath
                        print("  🔍 \(key.uppercased()) -> Found: \(foundPath)")
                    } else {
                        print("  ⚠️ \(key.uppercased()) -> App not found: \(path)")
                        continue
                    }
                }

                if fileManager.fileExists(atPath: effectivePath) {
                    validShortcuts[key] = effectivePath
                    print("  ✅ \(key.uppercased()) -> \(URL(fileURLWithPath: effectivePath).lastPathComponent)")
                }
            }
            newConfig.shortcuts = validShortcuts

            // 冲突检测：同一个应用被多个快捷键绑定
            var appToKeys: [String: [String]] = [:]
            for (key, path) in newConfig.shortcuts {
                appToKeys[path, default: []].append(key)
            }
            for (path, keys) in appToKeys where keys.count > 1 {
                print("  ⚠️ 冲突: \(URL(fileURLWithPath: path).lastPathComponent) 被多个快捷键绑定: \(keys.map { $0.uppercased() }.joined(separator: ", "))")
            }

            // 更新配置
            config = newConfig
            print("✅ Config loaded: \(config.shortcuts.count) valid shortcuts")

            watchForChanges()

        } catch {
            print("❌ Error loading config: \(error)")
            print("⚠️ Keeping previous config with \(config.shortcuts.count) shortcuts")
            // 不重置配置，保留之前的
        }
    }

    func openConfigFile() {
        NSWorkspace.shared.open(configPath)
    }

    func saveSettings() {
        // 暂停文件监听避免循环
        source?.cancel()
        fileHandle?.closeFile()

        do {
            let encoder = YAMLEncoder()
            let yamlString = try encoder.encode(config)
            try yamlString.write(to: configPath, atomically: true, encoding: .utf8)
            print("✅ Settings saved")
        } catch {
            print("❌ Error saving settings: \(error)")
        }

        // 恢复文件监听
        watchForChanges()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        config.settings.launchAtLogin = enabled
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
            if fileManager.fileExists(atPath: appPath) {
                return appPath
            }
        }
        return nil
    }

    private func createDefaultConfigIfNotExists() {
        let configDir = configPath.deletingLastPathComponent()

        if !fileManager.fileExists(atPath: configDir.path) {
            try? fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: configPath.path) {
            let defaultConfig = """
                # SpaceLauncher Configuration
                # Press and hold Space, then press a key to launch the app

                settings:
                  hold_threshold_ms: 150

                shortcuts:
                  # Communication
                  d: /Applications/DingTalk.app
                  w: /Applications/WeChat.app

                  # Development
                  v: /Applications/Visual Studio Code.app
                  t: /System/Applications/Terminal.app

                  # Browser & Tools
                  c: /Applications/Google Chrome.app
                  f: /System/Library/CoreServices/Finder.app
                """

            try? defaultConfig.write(to: configPath, atomically: true, encoding: .utf8)
            print("Created default config at: \(configPath.path)")
        }
    }

    private func watchForChanges() {
        source?.cancel()
        fileHandle?.closeFile()

        guard let handle = try? FileHandle(forReadingFrom: configPath) else { return }
        fileHandle = handle

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: handle.fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global()
        )

        source?.setEventHandler { [weak self] in
            print("📝 Config file changed, reloading...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.loadConfig()
                self?.onConfigChanged?()
            }
        }

        source?.resume()
    }
}