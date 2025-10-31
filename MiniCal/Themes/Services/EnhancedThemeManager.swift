//
//  EnhancedThemeManager.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Enhanced Theme Manager

/// 增强主题管理器 - 负责主题加载、切换、预览和持久化存储
class EnhancedThemeManager: ObservableObject {
    static let shared = EnhancedThemeManager()

    // MARK: - Published Properties
    @Published var currentMode: ThemeMode = .auto
    @Published var lightTheme: ThemeConfiguration = .defaultLight
    @Published var darkTheme: ThemeConfiguration = .defaultDark
    @Published var previewTheme: ThemeConfiguration?
    @Published var availableThemes: [ThemeConfiguration] = []

    // MARK: - Private Properties
    private let themeCache: ThemeCache
    private let preferencesStorage: UserPreferencesStorage
    private let systemAppearanceMonitor: SystemAppearanceMonitor
    private let performanceMonitor: PerformanceMonitor
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var effectiveTheme: ThemeConfiguration {
        if let previewTheme = previewTheme {
            return previewTheme
        }

        switch currentMode {
        case .light:
            return lightTheme
        case .dark:
            return darkTheme
        case .auto:
            return systemAppearanceMonitor.isDarkMode ? darkTheme : lightTheme
        }
    }

    var isPreviewing: Bool {
        return previewTheme != nil
    }

    // MARK: - Initialization
    private init() {
        self.themeCache = ThemeCache.shared
        self.preferencesStorage = UserPreferencesStorage.shared
        self.systemAppearanceMonitor = SystemAppearanceMonitor.shared
        self.performanceMonitor = PerformanceMonitor.shared

        loadPreferences()
        loadThemes()
        setupAppearanceObserver()
        setupPerformanceMonitoring()
    }

    // MARK: - Core Methods

    /// 加载所有可用主题
    func loadThemes() {
        performanceMonitor.measure(operation: "load_themes") {
            availableThemes = themeCache.allThemes()

            // 确保默认主题可用
            if themeCache.theme(for: lightTheme.id) == nil {
                lightTheme = .defaultLight
            }
            if themeCache.theme(for: darkTheme.id) == nil {
                darkTheme = .defaultDark
            }

            print("🎨 Loaded \(availableThemes.count) themes")
        }
    }

    /// 切换主题模式
    func switchToMode(_ mode: ThemeMode) {
        performanceMonitor.measureThemeSwitch(from: effectiveTheme, to: effectiveTheme) {
            currentMode = mode

            // 如果正在预览，停止预览
            if isPreviewing {
                stopPreview()
            }

            savePreferences()

            // 发送主题变化通知
            NotificationCenter.default.post(
                name: .themeDidChange,
                object: effectiveTheme,
                userInfo: [
                    "mode": mode,
                    "previousMode": currentMode == mode ? mode : (mode == .light ? .dark : .light)
                ]
            )
        }
    }

    /// 设置特定主题
    func setTheme(_ theme: ThemeConfiguration, for category: ThemeCategory) {
        performanceMonitor.measureThemeSwitch(from: effectiveTheme, to: theme) {
            let previousTheme = effectiveTheme

            switch category {
            case .light:
                lightTheme = theme
            case .dark:
                darkTheme = theme
            }

            // 如果正在预览，停止预览
            if isPreviewing {
                stopPreview()
            }

            savePreferences()

            // 发送主题变化通知
            NotificationCenter.default.post(
                name: .themeDidChange,
                object: effectiveTheme,
                userInfo: [
                    "theme": theme,
                    "category": category.rawValue,
                    "previousTheme": previousTheme
                ]
            )
        }
    }

    /// 开始主题预览
    func startPreview(theme: ThemeConfiguration) {
        performanceMonitor.measureThemePreview {
            previewTheme = theme

            NotificationCenter.default.post(
                name: .themePreviewStarted,
                object: theme,
                userInfo: ["previewTheme": theme]
            )
        }
    }

    /// 停止主题预览
    func stopPreview() {
        let previousPreviewTheme = previewTheme
        previewTheme = nil

        NotificationCenter.default.post(
            name: .themePreviewStopped,
            object: nil,
            userInfo: [
                "previousPreviewTheme": previousPreviewTheme as Any,
                "effectiveTheme": effectiveTheme
            ]
        )
    }

    // MARK: - Persistence

    /// 保存用户偏好设置
    func savePreferences() {
        var userPreferences = UserThemePreferences()
        userPreferences.mode = currentMode
        userPreferences.lightThemeId = lightTheme.id
        userPreferences.darkThemeId = darkTheme.id
        userPreferences.enableRealTimePreview = true
        userPreferences.enableSmoothTransitions = true
        userPreferences.lastUsedVersion = "1.0"

        let success = preferencesStorage.savePreferences(userPreferences)
        if !success {
            print("⚠️ Failed to save theme preferences")
        }
    }

    /// 加载用户偏好设置
    func loadPreferences() {
        let userPreferences = preferencesStorage.loadPreferences()

        currentMode = userPreferences.mode

        // 加载用户选择的主题
        if let lightTheme = themeCache.theme(for: userPreferences.lightThemeId) {
            self.lightTheme = lightTheme
        } else {
            self.lightTheme = .defaultLight
        }

        if let darkTheme = themeCache.theme(for: userPreferences.darkThemeId) {
            self.darkTheme = darkTheme
        } else {
            self.darkTheme = .defaultDark
        }

        print("🎨 Loaded preferences: mode=\(currentMode), light=\(self.lightTheme.id), dark=\(self.darkTheme.id)")
    }

    // MARK: - Utilities

    /// 根据ID获取主题
    func theme(for id: String) -> ThemeConfiguration? {
        return themeCache.theme(for: id)
    }

    /// 根据分类获取主题
    func themes(for category: ThemeCategory) -> [ThemeConfiguration] {
        return availableThemes.filter { $0.category == category }
    }

    /// 重置到默认设置
    func resetToDefaults() {
        performanceMonitor.measure(operation: "reset_to_defaults") {
            lightTheme = .defaultLight
            darkTheme = .defaultDark
            currentMode = .auto
            previewTheme = nil

            savePreferences()

            NotificationCenter.default.post(
                name: .themeDidReset,
                object: nil,
                userInfo: ["message": "Theme settings reset to defaults"]
            )
        }
    }

    /// 获取主题统计信息
    func getThemeStatistics() -> ThemeStatistics {
        let lightThemes = themes(for: .light)
        let darkThemes = themes(for: .dark)
        let builtinThemes = availableThemes.filter { $0.isBuiltIn }
        let customThemes = availableThemes.filter { !$0.isBuiltIn }

        return ThemeStatistics(
            totalThemes: availableThemes.count,
            lightThemes: lightThemes.count,
            darkThemes: darkThemes.count,
            builtinThemes: builtinThemes.count,
            customThemes: customThemes.count,
            currentMode: currentMode,
            currentTheme: effectiveTheme.id,
            isPreviewing: isPreviewing
        )
    }

    /// 验证主题配置
    func validateTheme(_ theme: ThemeConfiguration) -> [ValidationError] {
        return theme.validate()
    }

    /// 导出主题配置
    func exportTheme(_ theme: ThemeConfiguration) -> Data? {
        return themeCache.exportTheme(theme)
    }

    /// 导入主题配置
    func importTheme(from data: Data) -> ThemeConfiguration? {
        guard let theme = themeCache.importTheme(from: data) else {
            return nil
        }

        // 重新加载可用主题列表
        loadThemes()

        return theme
    }

    // MARK: - Private Methods

    /// 设置外观变化观察器
    private func setupAppearanceObserver() {
        // 监听系统外观变化
        systemAppearanceMonitor.$isDarkMode
            .removeDuplicates()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleSystemAppearanceChange()
                }
            }
            .store(in: &cancellables)

        // 监听主题变化通知
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handleThemeChange(notification: notification)
                }
            }
            .store(in: &cancellables)
    }

    /// 设置性能监控
    private func setupPerformanceMonitoring() {
        // 监控主题切换性能
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] notification in
                guard let self = self else { return }

                if let theme = notification.object as? ThemeConfiguration {
                    let stats = self.performanceMonitor.getPerformanceStatistics()
                    if let operationStats = stats.operationStatistics["theme_switch"] {
                        if operationStats.averageDuration > 0.1 {
                            print("⚠️ Slow theme switch detected: \(operationStats.averageDuration * 1000)ms")
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// 处理系统外观变化
    private func handleSystemAppearanceChange() {
        // 只有在自动模式下才需要响应系统外观变化
        guard currentMode == .auto else { return }

        let newEffectiveTheme = effectiveTheme
        NotificationCenter.default.post(
            name: .effectiveThemeDidChange,
            object: newEffectiveTheme,
            userInfo: [
                "trigger": "system_appearance_change",
                "isDarkMode": systemAppearanceMonitor.isDarkMode
            ]
        )
    }

    /// 处理主题变化
    private func handleThemeChange(notification: Notification) {
        objectWillChange.send()

        if let userInfo = notification.userInfo {
            print("🎨 Theme changed: \(userInfo)")
        }
    }
}

// MARK: - Supporting Types

/// 主题统计信息
struct ThemeStatistics {
    let totalThemes: Int
    let lightThemes: Int
    let darkThemes: Int
    let builtinThemes: Int
    let customThemes: Int
    let currentMode: ThemeMode
    let currentTheme: String
    let isPreviewing: Bool
}

// MARK: - Notification Names

extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
    static let themePreviewStarted = Notification.Name("ThemePreviewStarted")
    static let themePreviewStopped = Notification.Name("ThemePreviewStopped")
    static let effectiveThemeDidChange = Notification.Name("EffectiveThemeDidChange")
    static let themeDidReset = Notification.Name("ThemeDidReset")
    static let themeModeChanged = Notification.Name("ThemeModeChanged")
}

// MARK: - Enhanced Theme Manager Extensions

extension EnhancedThemeManager {
    /// 获取适合当前模式的主题列表
    func themesForCurrentMode() -> [ThemeConfiguration] {
        switch currentMode {
        case .light:
            return themes(for: .light)
        case .dark:
            return themes(for: .dark)
        case .auto:
            // 在自动模式下显示所有主题，但按分组显示
            return availableThemes
        }
    }

    /// 获取当前有效的主题分类
    func effectiveCategory() -> ThemeCategory {
        switch currentMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return systemAppearanceMonitor.isDarkMode ? .dark : .light
        }
    }

    /// 切换到下一个主题模式
    func switchToNextMode() {
        let allModes: [ThemeMode] = [.light, .dark, .auto]
        if let currentIndex = allModes.firstIndex(of: currentMode) {
            let nextIndex = (currentIndex + 1) % allModes.count
            switchToMode(allModes[nextIndex])
        }
    }

    /// 应用主题（带动画）
    func applyTheme(_ theme: ThemeConfiguration, animated: Bool = true) {
        let category = theme.category
        setTheme(theme, for: category)

        if animated {
            // 触发UI动画
            NotificationCenter.default.post(
                name: .themeAnimationRequested,
                object: theme,
                userInfo: ["animated": true]
            )
        }
    }

    /// 批量应用主题设置
    func applyThemeSettings(mode: ThemeMode, lightTheme: ThemeConfiguration?, darkTheme: ThemeConfiguration?) {
        currentMode = mode

        if let lightTheme = lightTheme {
            self.lightTheme = lightTheme
        }

        if let darkTheme = darkTheme {
            self.darkTheme = darkTheme
        }

        savePreferences()

        NotificationCenter.default.post(
            name: .themeDidChange,
            object: effectiveTheme,
            userInfo: [
                "batchUpdate": true,
                "mode": mode,
                "lightTheme": lightTheme?.id as Any,
                "darkTheme": darkTheme?.id as Any
            ]
        )
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let themeAnimationRequested = Notification.Name("ThemeAnimationRequested")
    static let themePreviewCancelled = Notification.Name("ThemePreviewCancelled")
    static let themeImportCompleted = Notification.Name("ThemeImportCompleted")
    static let themeExportCompleted = Notification.Name("ThemeExportCompleted")
}