import Foundation

struct Config: Codable {
    var settings: Settings
    var shortcuts: [String: String]

    struct Settings: Codable {
        var holdThresholdMs: Int
        var launchAtLogin: Bool
        var triggerKey: TriggerKey

        enum CodingKeys: String, CodingKey {
            case holdThresholdMs = "hold_threshold_ms"
            case launchAtLogin = "launch_at_login"
            case triggerKey = "trigger_key"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            holdThresholdMs = try container.decodeIfPresent(Int.self, forKey: .holdThresholdMs) ?? 150
            launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
            triggerKey = try container.decodeIfPresent(TriggerKey.self, forKey: .triggerKey) ?? .space
        }

        init() {
            holdThresholdMs = 150
            launchAtLogin = false
            triggerKey = .space
        }
    }

    /// 触发键类型
    enum TriggerKey: String, Codable {
        case space = "space"
        case capsLock = "caps_lock"
        case esc = "esc"

        /// macOS keyCode
        var keyCode: Int64 {
            switch self {
            case .space: return 49
            case .capsLock: return 57
            case .esc: return 53
            }
        }

        /// 是否是修饰键（需要 flagsChanged 事件处理）
        var isModifierKey: Bool {
            return self == .capsLock
        }

        /// 显示名称
        var displayName: String {
            switch self {
            case .space: return "空格"
            case .capsLock: return "大写锁定"
            case .esc: return "ESC"
            }
        }
    }

    init() {
        settings = Settings()
        shortcuts = [:]
    }
}

struct Shortcut {
    let key: String
    let appPath: String
    let appName: String

    init(key: String, appPath: String) {
        self.key = key
        self.appPath = appPath
        self.appName = URL(fileURLWithPath: appPath).deletingPathExtension().lastPathComponent
    }
}