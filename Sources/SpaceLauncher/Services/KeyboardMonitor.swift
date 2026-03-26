import Foundation
import Carbon
import AppKit

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var configManager: ConfigManager

    private var spacePressed = false
    private var spacePressTime: Date?
    private var inWaitingMode = false
    private var holdTimer: DispatchWorkItem?
    private var isPaused = false

    private let onWaitingMode: () -> Void
    private let onShortcutTriggered: (Shortcut) -> Void
    private let onModeEnded: () -> Void

    init(
        configManager: ConfigManager,
        onWaitingMode: @escaping () -> Void,
        onShortcutTriggered: @escaping (Shortcut) -> Void,
        onModeEnded: @escaping () -> Void
    ) {
        self.configManager = configManager
        self.onWaitingMode = onWaitingMode
        self.onShortcutTriggered = onShortcutTriggered
        self.onModeEnded = onModeEnded
    }

    deinit {
        stop()
    }

    func start() {
        let trusted = AXIsProcessTrusted()
        print("Accessibility trusted: \(trusted)")

        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            print("Requesting accessibility permission...")
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap - check accessibility permission!")
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("✅ Keyboard monitor started successfully")
        print("📋 Config: \(configManager.config.shortcuts.count) shortcuts loaded")
    }

    func stop() {
        holdTimer?.cancel()
        holdTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        print("Keyboard monitor stopped")
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        if paused {
            // 重置状态
            spacePressed = false
            inWaitingMode = false
            holdTimer?.cancel()
            holdTimer = nil
        }
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 如果暂停，直接放行所有事件
        if isPaused {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let spaceKeyCode: Int64 = 49 // Space key code

        // 处理 Space 键
        if keyCode == spaceKeyCode {
            switch type {
            case .keyDown:
                if !spacePressed {
                    spacePressed = true
                    spacePressTime = Date()

                    holdTimer?.cancel()

                    let threshold = Double(configManager.config.settings.holdThresholdMs) / 1000.0
                    let timer = DispatchWorkItem { [weak self] in
                        guard let self = self else { return }
                        if self.spacePressed && !self.inWaitingMode {
                            self.inWaitingMode = true
                            DispatchQueue.main.async {
                                self.onWaitingMode()
                            }
                        }
                    }
                    holdTimer = timer

                    DispatchQueue.main.asyncAfter(deadline: .now() + threshold, execute: timer)
                }

                // 在等待模式下阻止 Space 输入
                if inWaitingMode {
                    return nil
                }

            case .keyUp:
                if spacePressed {
                    spacePressed = false
                    holdTimer?.cancel()
                    holdTimer = nil

                    if inWaitingMode {
                        inWaitingMode = false
                        DispatchQueue.main.async { [weak self] in
                            self?.onModeEnded()
                        }
                    }
                }

            default:
                break
            }

            return Unmanaged.passUnretained(event)
        }

        // 处理其他按键 - 在等待模式下可以连续触发
        if inWaitingMode && type == .keyDown {
            let char = getCharacterFromEvent(event: event)
            let key = char.lowercased()

            print("🔑 Key pressed: '\(key)' (Space held, can continue switching)")

            if let appPath = configManager.config.shortcuts[key] {
                print("🚀 Launching: \(appPath)")
                // 注意：不设置 inWaitingMode = false，允许连续切换
                // 只有松开 Space 时才会退出等待模式

                let shortcut = Shortcut(key: key, appPath: appPath)
                DispatchQueue.main.async { [weak self] in
                    self?.onShortcutTriggered(shortcut)
                }

                // 阻止这个按键的输入
                return nil
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func getCharacterFromEvent(event: CGEvent) -> String {
        var unicodeString = [UniChar](repeating: 0, count: 4)
        var length: Int = 0

        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &unicodeString)

        if length > 0 {
            return String(utf16CodeUnits: unicodeString, count: length)
        }

        return ""
    }
}