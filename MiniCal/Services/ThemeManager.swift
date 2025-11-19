//
//  ThemeManager.swift
//  MiniCal
//
//  Created by MiniCal on 2025/11/13.
//  统一的主题管理器，支持浅色/自动/深色模式
//

import SwiftUI
import Combine

/// 主题管理器，负责加载、应用和切换主题
class ThemeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Published Properties

    /// 当前主题模式（浅色/自动/深色）
    @Published private(set) var themeMode: ThemeMode = .auto

    /// 当前浅色主题
    @Published private(set) var currentLightTheme: ThemeConfiguration

    /// 当前深色主题
    @Published private(set) var currentDarkTheme: ThemeConfiguration

    // MARK: - Available Themes

    /// 所有可用的浅色主题
    let lightThemes: [ThemeConfiguration] = BuiltInThemes.lightThemes

    /// 所有可用的深色主题
    let darkThemes: [ThemeConfiguration] = BuiltInThemes.darkThemes

    // MARK: - Computed Properties

    /// 当前有效的主题配置（根据模式和系统外观）
    var effectiveTheme: ThemeConfiguration {
        switch themeMode {
        case .light:
            return currentLightTheme
        case .dark:
            return currentDarkTheme
        case .auto:
            return isSystemDarkMode ? currentDarkTheme : currentLightTheme
        }
    }

    /// 当前有效的主题颜色
    var effectiveColors: ThemeColors {
        return effectiveTheme.colors
    }

    /// 当前浅色主题ID
    var currentLightThemeId: String {
        currentLightTheme.id
    }

    /// 当前深色主题ID
    var currentDarkThemeId: String {
        currentDarkTheme.id
    }

    /// 系统是否处于深色模式
    private var isSystemDarkMode: Bool {
        NSApp.effectiveAppearance.name == .darkAqua
    }

    // MARK: - Private Properties

    private var appearanceObserver: NSKeyValueObservation?
    private let settingsManager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // 从设置加载主题配置
        let settings = settingsManager.currentSettings

        self.themeMode = settings.themeMode

        // 加载浅色主题
        if let lightTheme = lightThemes.first(where: { $0.id == settings.lightThemeId }) {
            self.currentLightTheme = lightTheme
        } else {
            self.currentLightTheme = BuiltInThemes.defaultLightTheme
            Logger.warning("Light theme '\(settings.lightThemeId)' not found, using default", category: Logger.theme)
        }

        // 加载深色主题
        if let darkTheme = darkThemes.first(where: { $0.id == settings.darkThemeId }) {
            self.currentDarkTheme = darkTheme
        } else {
            self.currentDarkTheme = BuiltInThemes.defaultDarkTheme
            Logger.warning("Dark theme '\(settings.darkThemeId)' not found, using default", category: Logger.theme)
        }

        // 如果是自动模式，开始监听系统外观
        if themeMode == .auto {
            startObservingSystemAppearance()
        }

        // 监听设置变化
        settingsManager.$currentSettings
            .sink { [weak self] newSettings in
                self?.handleSettingsChange(newSettings)
            }
            .store(in: &cancellables)

        Logger.info("ThemeManager initialized - Mode: \(themeMode.displayName), Light: \(currentLightTheme.displayName), Dark: \(currentDarkTheme.displayName)", category: Logger.theme)
    }

    // MARK: - Public Methods

    /// 设置主题模式
    func setThemeMode(_ mode: ThemeMode) {
        guard themeMode != mode else { return }

        Logger.info("Setting theme mode to '\(mode.displayName)'", category: Logger.theme)

        themeMode = mode

        // 保存到设置
        var settings = settingsManager.currentSettings
        settings.themeMode = mode
        settings.lastUpdated = Date()
        settingsManager.saveSettings(settings)

        // 更新系统外观监听
        if mode == .auto {
            startObservingSystemAppearance()
        } else {
            stopObservingSystemAppearance()
        }

        // 通知UI更新
        objectWillChange.send()
        postThemeChangeNotification()
    }

    /// 设置浅色主题
    func setLightTheme(_ theme: ThemeConfiguration) {
        guard theme.category == .light else {
            Logger.warning("Attempted to set non-light theme '\(theme.id)' as light theme", category: Logger.theme)
            return
        }

        Logger.info("Setting light theme to '\(theme.displayName)'", category: Logger.theme)

        currentLightTheme = theme

        // 保存到设置
        var settings = settingsManager.currentSettings
        settings.lightThemeId = theme.id
        settings.lastUpdated = Date()
        settingsManager.saveSettings(settings)

        // 如果当前应该显示浅色主题，通知更新
        if shouldShowLightTheme {
            objectWillChange.send()
            postThemeChangeNotification()
        }
    }

    /// 设置深色主题
    func setDarkTheme(_ theme: ThemeConfiguration) {
        guard theme.category == .dark else {
            Logger.warning("Attempted to set non-dark theme '\(theme.id)' as dark theme", category: Logger.theme)
            return
        }

        Logger.info("Setting dark theme to '\(theme.displayName)'", category: Logger.theme)

        currentDarkTheme = theme

        // 保存到设置
        var settings = settingsManager.currentSettings
        settings.darkThemeId = theme.id
        settings.lastUpdated = Date()
        settingsManager.saveSettings(settings)

        // 如果当前应该显示深色主题，通知更新
        if !shouldShowLightTheme {
            objectWillChange.send()
            postThemeChangeNotification()
        }
    }

    /// 重置为默认主题
    func resetToDefault() {
        Logger.info("Resetting themes to default", category: Logger.theme)

        themeMode = .auto
        currentLightTheme = BuiltInThemes.defaultLightTheme
        currentDarkTheme = BuiltInThemes.defaultDarkTheme

        // 保存到设置
        var settings = settingsManager.currentSettings
        settings.themeMode = .auto
        settings.lightThemeId = currentLightTheme.id
        settings.darkThemeId = currentDarkTheme.id
        settings.lastUpdated = Date()
        settingsManager.saveSettings(settings)

        // 开始监听系统外观
        startObservingSystemAppearance()

        // 通知UI更新
        objectWillChange.send()
        postThemeChangeNotification()
    }

    /// 根据ID查找主题（兼容旧API）
    func theme(withId id: String) -> ThemeConfiguration? {
        return BuiltInThemes.allThemes.first { $0.id == id }
    }

    // MARK: - System Appearance Observation

    /// 开始监听系统外观变化
    func startObservingSystemAppearance() {
        guard appearanceObserver == nil else { return }

        appearanceObserver = NSApp.observe(
            \.effectiveAppearance,
            options: [.new]
        ) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                self?.postThemeChangeNotification()
            }
        }

        Logger.debug("Started observing system appearance", category: Logger.theme)
    }

    /// 停止监听系统外观变化
    func stopObservingSystemAppearance() {
        appearanceObserver?.invalidate()
        appearanceObserver = nil
        Logger.debug("Stopped observing system appearance", category: Logger.theme)
    }

    // MARK: - Private Methods

    /// 当前是否应该显示浅色主题
    private var shouldShowLightTheme: Bool {
        switch themeMode {
        case .light:
            return true
        case .dark:
            return false
        case .auto:
            return !isSystemDarkMode
        }
    }

    /// 处理设置变化
    private func handleSettingsChange(_ newSettings: UserSettings) {
        var needsUpdate = false

        // 检查主题模式变化
        if newSettings.themeMode != themeMode {
            themeMode = newSettings.themeMode
            needsUpdate = true

            if themeMode == .auto {
                startObservingSystemAppearance()
            } else {
                stopObservingSystemAppearance()
            }

            Logger.debug("Theme mode changed to '\(themeMode.displayName)'", category: Logger.theme)
        }

        // 检查浅色主题变化
        if let newLightTheme = lightThemes.first(where: { $0.id == newSettings.lightThemeId }),
           newLightTheme.id != currentLightTheme.id {
            currentLightTheme = newLightTheme
            needsUpdate = true
            Logger.debug("Light theme changed to '\(newLightTheme.displayName)'", category: Logger.theme)
        }

        // 检查深色主题变化
        if let newDarkTheme = darkThemes.first(where: { $0.id == newSettings.darkThemeId }),
           newDarkTheme.id != currentDarkTheme.id {
            currentDarkTheme = newDarkTheme
            needsUpdate = true
            Logger.debug("Dark theme changed to '\(newDarkTheme.displayName)'", category: Logger.theme)
        }

        if needsUpdate {
            objectWillChange.send()
            postThemeChangeNotification()
        }
    }

    /// 发送主题变化通知
    private func postThemeChangeNotification() {
        NotificationCenter.default.post(
            name: .themeDidChange,
            object: effectiveTheme
        )
    }

    // MARK: - Deinit

    deinit {
        stopObservingSystemAppearance()
    }
}

// MARK: - Notification Name

extension Notification.Name {
    /// 主题变化通知
    static let themeDidChange = Notification.Name("ThemeDidChange")

    /// 主题预览请求通知（用于触发日历浮窗显示）
    static let themePreviewRequested = Notification.Name("ThemePreviewRequested")

    /// 重置日历到今天通知
    static let resetCalendarToToday = Notification.Name("ResetCalendarToToday")
}
