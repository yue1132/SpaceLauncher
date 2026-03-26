import Foundation

struct Config: Codable {
    var settings: Settings
    var shortcuts: [String: String]

    struct Settings: Codable {
        var holdThresholdMs: Int
        var launchAtLogin: Bool

        enum CodingKeys: String, CodingKey {
            case holdThresholdMs = "hold_threshold_ms"
            case launchAtLogin = "launch_at_login"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            holdThresholdMs = try container.decodeIfPresent(Int.self, forKey: .holdThresholdMs) ?? 150
            launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        }

        init() {
            holdThresholdMs = 150
            launchAtLogin = false
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