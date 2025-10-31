//
//  SystemAppearanceMonitor.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI
import AppKit
import Combine

// MARK: - System Appearance Monitor Protocol

protocol SystemAppearanceMonitorProtocol: ObservableObject {
    var isDarkMode: Bool { get }
    var systemAppearance: NSAppearance.Name { get }
    var effectiveColorScheme: ColorScheme? { get }

    func startMonitoring()
    func stopMonitoring()
    func refreshAppearance()
}

// MARK: - System Appearance Monitor

/// 系统外观监控器
class SystemAppearanceMonitor: ObservableObject, SystemAppearanceMonitorProtocol {
    static let shared = SystemAppearanceMonitor()

    @Published var isDarkMode: Bool = false
    @Published var systemAppearance: NSAppearance.Name = .aqua
    @Published var effectiveColorScheme: ColorScheme? = .light

    private var appearanceObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.3
    private var debounceWorkItem: DispatchWorkItem?
    private var appearanceHistory: [AppearanceChangeRecord] = []
    private let maxHistoryCount = 10

    // MARK: - Initialization

    private init() {
        setupInitialAppearance()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Appearance Monitoring

    /// 开始监控系统外观变化
    func startMonitoring() {
        guard appearanceObserver == nil else { return }

        // 监听系统外观变化通知
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("NSApplicationDidChangeEffectiveAppearance"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppearanceChange()
        }

        print("🎨 System appearance monitoring started")
    }

    /// 停止监控系统外观变化
    func stopMonitoring() {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
            appearanceObserver = nil
        }

        debounceWorkItem?.cancel()
        cancellables.removeAll()

        print("🎨 System appearance monitoring stopped")
    }

    /// 刷新当前外观状态
    func refreshAppearance() {
        updateAppearanceState()
    }

    // MARK: - Private Methods

    /// 设置初始外观状态
    private func setupInitialAppearance() {
        updateAppearanceState()
    }

    /// 处理外观变化
    private func handleAppearanceChange() {
        // 使用防抖动来避免频繁更新
        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.updateAppearanceState()
        }

        if let workItem = debounceWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
        }
    }

    /// 更新外观状态
    private func updateAppearanceState() {
        let newAppearance = NSApp.effectiveAppearance.name
        let newIsDarkMode = isDarkAppearance(newAppearance)
        let newColorScheme = newIsDarkMode ? ColorScheme.dark : ColorScheme.light

        // 检查是否需要更新
        guard systemAppearance != newAppearance ||
              isDarkMode != newIsDarkMode ||
              effectiveColorScheme != newColorScheme else {
            return
        }

        let oldAppearance = systemAppearance
        let oldIsDarkMode = isDarkMode

        // 更新状态
        systemAppearance = newAppearance
        isDarkMode = newIsDarkMode
        effectiveColorScheme = newColorScheme

        // 发送通知
        NotificationCenter.default.post(
            name: .systemAppearanceDidChange,
            object: self,
            userInfo: [
                "oldAppearance": oldAppearance,
                "newAppearance": newAppearance,
                "oldIsDarkMode": oldIsDarkMode,
                "newIsDarkMode": newIsDarkMode
            ]
        )

        print("🎨 System appearance changed: \(oldAppearance) → \(newAppearance) (Dark mode: \(newIsDarkMode))")
    }

    /// 判断是否为深色外观
    private func isDarkAppearance(_ appearance: NSAppearance.Name) -> Bool {
        switch appearance {
        case .darkAqua, .vibrantDark:
            return true
        case .aqua, .vibrantLight:
            return false
        default:
            // 检查最佳匹配外观
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }
}

// MARK: - System Appearance Extensions

extension SystemAppearanceMonitor {
    /// 获取当前主题模式建议
    func suggestedThemeMode(for userPreference: ThemeMode) -> ThemeMode {
        switch userPreference {
        case .light, .dark:
            return userPreference
        case .auto:
            return isDarkMode ? .dark : .light
        }
    }

    /// 获取适合当前外观的主题分类
    func appropriateThemeCategory() -> ThemeCategory {
        return isDarkMode ? .dark : .light
    }

    /// 监听外观变化并执行回调
    func onAppearanceChange(perform action: @escaping (Bool) -> Void) -> AnyCancellable {
        return $isDarkMode
            .removeDuplicates()
            .sink { isDark in
                action(isDark)
            }
    }
}

// MARK: - Appearance Transition Manager

/// 外观过渡管理器
class AppearanceTransitionManager: ObservableObject {
    @Published var isTransitioning: Bool = false
    @Published var transitionProgress: Double = 0.0

    private let transitionDuration: TimeInterval = 0.3
    private var transitionTimer: Timer?

    /// 开始外观过渡动画
    func startTransition(from oldAppearance: NSAppearance.Name, to newAppearance: NSAppearance.Name) {
        guard !isTransitioning else { return }

        isTransitioning = true
        transitionProgress = 0.0

        // 创建过渡动画
        transitionTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.transitionProgress += 1.0 / (self.transitionDuration / 0.016)

            if self.transitionProgress >= 1.0 {
                self.transitionProgress = 1.0
                self.isTransitioning = false
                timer.invalidate()
            }
        }
    }

    /// 停止过渡动画
    func stopTransition() {
        transitionTimer?.invalidate()
        transitionTimer = nil
        isTransitioning = false
        transitionProgress = 1.0
    }
}

// MARK: - Color Scheme Manager

/// 颜色方案管理器
class ColorSchemeManager: ObservableObject {
    @Published var currentColorScheme: ColorScheme = .light

    private let systemMonitor = SystemAppearanceMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupColorSchemeMonitoring()
    }

    /// 设置颜色方案监控
    private func setupColorSchemeMonitoring() {
        systemMonitor.$isDarkMode
            .map { isDark in
                isDark ? ColorScheme.dark : ColorScheme.light
            }
            .assign(to: &$currentColorScheme)
    }

    /// 获取适合的颜色方案
    func colorScheme(for mode: ThemeMode) -> ColorScheme {
        switch mode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return currentColorScheme
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let systemAppearanceDidChange = Notification.Name("SystemAppearanceDidChange")
    static let systemAppearanceWillChange = Notification.Name("SystemAppearanceWillChange")
    static let themeModeShouldUpdate = Notification.Name("ThemeModeShouldUpdate")
    static let effectiveAppearanceChanged = Notification.Name("EffectiveAppearanceChanged")
}

// MARK: - Appearance Utilities

struct AppearanceUtilities {
    /// 获取当前系统外观信息
    static func getCurrentAppearanceInfo() -> AppearanceInfo {
        let appearance = NSApp.effectiveAppearance
        let name = appearance.name
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        return AppearanceInfo(
            name: name,
            isDark: isDark,
            description: appearanceDescription(name)
        )
    }

    /// 获取外观描述
    private static func appearanceDescription(_ name: NSAppearance.Name) -> String {
        switch name {
        case .aqua:
            return "Light Mode (Aqua)"
        case .darkAqua:
            return "Dark Mode (Dark Aqua)"
        case .vibrantLight:
            return "Vibrant Light"
        case .vibrantDark:
            return "Vibrant Dark"
        default:
            return "Unknown Appearance"
        }
    }

    /// 检查系统是否支持深色模式
    static func supportsDarkMode() -> Bool {
        if #available(macOS 10.14, *) {
            return true
        }
        return false
    }

    /// 获取系统版本信息
    static func getSystemVersionInfo() -> SystemVersionInfo {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        return SystemVersionInfo(
            majorVersion: version.majorVersion,
            minorVersion: version.minorVersion,
            patchVersion: version.patchVersion,
            versionString: versionString,
            supportsDarkMode: supportsDarkMode()
        )
    }
}

// MARK: - Supporting Types

/// 外观信息
struct AppearanceInfo {
    let name: NSAppearance.Name
    let isDark: Bool
    let description: String
}

/// 系统版本信息
struct SystemVersionInfo {
    let majorVersion: Int
    let minorVersion: Int
    let patchVersion: Int
    let versionString: String
    let supportsDarkMode: Bool
}

// MARK: - Debug and Logging

extension SystemAppearanceMonitor {
    /// 启用调试日志
    func enableDebugLogging() {
        // 在调试模式下，记录更详细的信息
        print("🎨 System Appearance Monitor Debug Info:")
        print("  Current appearance: \(systemAppearance)")
        print("  Is dark mode: \(isDarkMode)")
        print("  Effective color scheme: \(effectiveColorScheme != nil ? (effectiveColorScheme == .dark ? "dark" : "light") : "nil")")
        print("  macOS version: \(AppearanceUtilities.getSystemVersionInfo().versionString)")
        print("  Supports dark mode: \(AppearanceUtilities.supportsDarkMode())")
    }

    private func recordAppearanceChange(from: NSAppearance.Name, to: NSAppearance.Name) {
        let record = AppearanceChangeRecord(
            timestamp: Date(),
            fromAppearance: from,
            toAppearance: to,
            isDarkMode: isDarkMode
        )

        appearanceHistory.append(record)

        if appearanceHistory.count > maxHistoryCount {
            appearanceHistory.removeFirst()
        }
    }
}

/// 外观变化记录
private struct AppearanceChangeRecord {
    let timestamp: Date
    let fromAppearance: NSAppearance.Name
    let toAppearance: NSAppearance.Name
    let isDarkMode: Bool
}