import Foundation
import Carbon
import AppKit

class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var configManager: ConfigManager
    private var retryTimer: DispatchWorkItem?

    private var triggerPressed = false
    private var triggerPressTime: Date?
    private var inWaitingMode = false
    private var holdTimer: DispatchWorkItem?
    private var isPaused = false
    private var stateWatchdogTimer: DispatchWorkItem?

    // Caps Lock 状态追踪（Caps Lock 是修饰键，需要特殊处理）
    private var capsLockWasOn = false

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
        // 先检查权限状态（不弹窗）
        let trusted = AXIsProcessTrusted()
        print("Accessibility trusted: \(trusted)")

        if trusted {
            // 权限已授予，直接启动
            createEventTap()
        } else {
            // 权限未授予，静默等待用户在系统设置中授权
            // 不主动弹窗，让 AppDelegate 处理 UI 提示
            waitForPermissionSilently()
        }
    }

    /// 静默等待权限生效（不弹窗）
    private func waitForPermissionSilently() {
        retryTimer?.cancel()

        let timer = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // 只检查状态，不弹窗
            let trusted = AXIsProcessTrusted()
            print("⏳ Checking permission status: \(trusted)")

            if trusted {
                print("✅ Permission granted, starting keyboard monitor...")
                self.createEventTap()
            } else {
                // 继续静默等待，每2秒检查一次
                self.waitForPermissionSilently()
            }
        }
        retryTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: timer)
    }

    /// 创建 event tap（可能失败后重试）
    private func createEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)

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
            print("❌ Failed to create event tap - will retry in 2 seconds...")

            // 权限可能还在生效中，延迟重试
            retryTimer?.cancel()
            let timer = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.createEventTap()
            }
            retryTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: timer)
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("✅ Keyboard monitor started successfully")
        print("📋 Config: \(configManager.config.shortcuts.count) shortcuts loaded")

        // 启动状态监控
        startStateWatchdog()
    }

    func stop() {
        retryTimer?.cancel()
        retryTimer = nil
        holdTimer?.cancel()
        holdTimer = nil
        stateWatchdogTimer?.cancel()
        stateWatchdogTimer = nil

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
            triggerPressed = false
            inWaitingMode = false
            holdTimer?.cancel()
            holdTimer = nil
            stateWatchdogTimer?.cancel()
            stateWatchdogTimer = nil
            retryTimer?.cancel()
            retryTimer = nil
        } else {
            // 恢复时重新启动 watchdog（如果 event tap 已经运行）
            if eventTap != nil {
                startStateWatchdog()
            }
        }
    }

    private func startStateWatchdog() {
        stateWatchdogTimer?.cancel()

        let timer = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.triggerPressed && self.triggerPressTime != nil {
                let elapsed = Date().timeIntervalSince(self.triggerPressTime!)
                if elapsed > 5.0 {
                    print("⚠️ State watchdog: resetting stuck state (held for \(elapsed)s)")
                    self.triggerPressed = false
                    self.inWaitingMode = false
                    self.holdTimer?.cancel()
                    self.holdTimer = nil
                    DispatchQueue.main.async {
                        self.onModeEnded()
                    }
                }
            }
            // 继续监控
            self.startStateWatchdog()
        }
        stateWatchdogTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: timer)
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 处理 tap 被禁用的情况
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("⚠️ Event tap was disabled (\(type)), re-enabling...")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                print("✅ Event tap re-enabled")
            }
            return Unmanaged.passUnretained(event)
        }

        // 如果暂停，直接放行所有事件
        if isPaused {
            return Unmanaged.passUnretained(event)
        }

        let triggerKey = configManager.config.settings.triggerKey
        let triggerKeyCode = triggerKey.keyCode

        // 处理 Caps Lock（flagsChanged 事件）
        if triggerKey == .capsLock && type == .flagsChanged {
            return handleCapsLockEvent(event: event)
        }

        // 处理其他修饰键变化 - 如果在等待模式/按住触发键期间按下修饰键，退出模式
        if type == .flagsChanged {
            let flags = event.flags
            // Shift 单独按下时不退出（允许 Shift+字母快捷键）
            let hasNonShiftModifier = flags.contains(.maskCommand) ||
                                       flags.contains(.maskAlternate) ||
                                       flags.contains(.maskControl)

            if hasNonShiftModifier && (triggerPressed || inWaitingMode) {
                print("⌨️ Modifier key changed during trigger hold, exiting mode")
                triggerPressed = false
                inWaitingMode = false
                holdTimer?.cancel()
                holdTimer = nil
                DispatchQueue.main.async { [weak self] in
                    self?.onModeEnded()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // 处理触发键（Space、ESC 等普通按键）
        if keyCode == triggerKeyCode && !triggerKey.isModifierKey {
            return handleTriggerKeyEvent(type: type, event: event)
        }

        // 处理其他按键 - 在等待模式下可以连续触发
        if inWaitingMode && type == .keyDown {
            let char = getCharacterFromEvent(event: event)
            let key = char.lowercased()

            print("🔑 Key pressed: '\(key)' (Trigger held, can continue switching)")

            if let appPath = configManager.config.shortcuts[key] {
                print("🚀 Launching: \(appPath)")
                // 注意：不设置 inWaitingMode = false，允许连续切换
                // 只有松开触发键时才会退出等待模式

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

    /// 处理 Caps Lock 事件（flagsChanged）
    private func handleCapsLockEvent(event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let capsLockOn = flags.contains(.maskAlphaShift)

        // 检查修饰键状态 - 如果有其他修饰键按下，让系统处理
        let hasOtherModifier = flags.contains(.maskCommand) ||
                               flags.contains(.maskAlternate) ||
                               flags.contains(.maskControl) ||
                               flags.contains(.maskShift)

        if hasOtherModifier {
            // 有修饰键按下，重置状态并让系统处理
            if triggerPressed || inWaitingMode {
                print("⌨️ Modifier key detected with Caps Lock, letting system handle")
                triggerPressed = false
                inWaitingMode = false
                holdTimer?.cancel()
                holdTimer = nil
                DispatchQueue.main.async { [weak self] in
                    self?.onModeEnded()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        // Caps Lock 状态变化检测
        if capsLockOn && !capsLockWasOn {
            // Caps Lock 刚被按下（开启）
            print("⌨️ Caps Lock pressed (ON)")
            capsLockWasOn = true
            triggerPressed = true
            triggerPressTime = Date()

            holdTimer?.cancel()

            let threshold = Double(configManager.config.settings.holdThresholdMs) / 1000.0
            let timer = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.triggerPressed && !self.inWaitingMode {
                    self.inWaitingMode = true
                    DispatchQueue.main.async {
                        self.onWaitingMode()
                    }
                }
            }
            holdTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + threshold, execute: timer)

            // 拦截 Caps Lock 开启事件（等待模式下）
            if inWaitingMode {
                return nil
            }

        } else if !capsLockOn && capsLockWasOn {
            // Caps Lock 刚被松开（关闭）
            print("⌨️ Caps Lock released (OFF)")
            capsLockWasOn = false
            triggerPressed = false
            holdTimer?.cancel()
            holdTimer = nil

            if inWaitingMode {
                inWaitingMode = false
                DispatchQueue.main.async { [weak self] in
                    self?.onModeEnded()
                }
                // 拦截等待模式下的 Caps Lock 关闭事件
                return nil
            }
        }

        return Unmanaged.passUnretained(event)
    }

    /// 处理触发键事件（Space 等普通按键）
    private func handleTriggerKeyEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 检查修饰键状态 - 如果有修饰键按下，让系统处理
        let flags = event.flags
        let hasModifier = flags.contains(.maskCommand) ||
                          flags.contains(.maskAlternate) ||
                          flags.contains(.maskControl) ||
                          flags.contains(.maskShift)

        if hasModifier {
            // 有修饰键按下，重置状态并让系统处理
            if triggerPressed || inWaitingMode {
                print("⌨️ Modifier key detected, letting system handle")
                triggerPressed = false
                inWaitingMode = false
                holdTimer?.cancel()
                holdTimer = nil
                DispatchQueue.main.async { [weak self] in
                    self?.onModeEnded()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .keyDown:
            if !triggerPressed {
                triggerPressed = true
                triggerPressTime = Date()

                holdTimer?.cancel()

                let threshold = Double(configManager.config.settings.holdThresholdMs) / 1000.0
                let timer = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    if self.triggerPressed && !self.inWaitingMode {
                        self.inWaitingMode = true
                        DispatchQueue.main.async {
                            self.onWaitingMode()
                        }
                    }
                }
                holdTimer = timer

                DispatchQueue.main.asyncAfter(deadline: .now() + threshold, execute: timer)
            }

            // 等待模式下拦截触发键，否则正常传递给应用
            if inWaitingMode {
                return nil
            }

        case .keyUp:
            if triggerPressed {
                triggerPressed = false
                holdTimer?.cancel()
                holdTimer = nil

                if inWaitingMode {
                    inWaitingMode = false
                    DispatchQueue.main.async { [weak self] in
                        self?.onModeEnded()
                    }
                    // 拦截等待模式下的触发键释放
                    return nil
                }
            }

        default:
            break
        }

        // 非等待模式下，触发键正常传递给应用
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