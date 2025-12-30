//
//  SettingsManager.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var currentSettings: UserSettings

    private let userDefaults: UserDefaults
    private let settingsKey = "MiniCalUserSettings"

    // 防抖机制：避免短时间内频繁保存设置
    private var settingsSaveDebouncer: DispatchWorkItem?
    private let debounceDelay: TimeInterval = 0.5 // 500ms 防抖延迟
    private var pendingSettings: UserSettings?

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // 检查是否是首次启动（无保存的设置）
        let isFirstLaunch = userDefaults.data(forKey: settingsKey) == nil

        if isFirstLaunch {
            // 首次启动：使用自动检测的默认设置
            self.currentSettings = UserSettings.default
            Logger.info("First launch detected, using auto-detected calendar defaults", category: Logger.settings)
        } else {
            // 非首次启动：从 UserDefaults 加载
            if let data = userDefaults.data(forKey: settingsKey) {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    self.currentSettings = try decoder.decode(UserSettings.self, from: data)
                } catch {
                    Logger.error("Failed to decode settings on init", error: error, category: Logger.settings)
                    self.currentSettings = UserSettings.default
                }
            } else {
                self.currentSettings = UserSettings.default
            }
        }

        // 首次启动时保存默认设置
        if isFirstLaunch {
            saveSettings(self.currentSettings)
        }
    }

    // MARK: - Load Settings

    func loadSettings() -> UserSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return UserSettings.default
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let settings = try decoder.decode(UserSettings.self, from: data)
            return settings
        } catch {
            Logger.error("Failed to decode settings", error: error, category: Logger.settings)
            return UserSettings.default
        }
    }

    // MARK: - Save Settings

    /// 保存设置（带防抖机制）
    /// - Parameter settings: 要保存的设置
    /// - Parameter immediate: 是否立即保存（默认 false，使用防抖）
    func saveSettings(_ settings: UserSettings, immediate: Bool = false) {
        // 保存待保存的设置
        pendingSettings = settings

        if immediate {
            // 立即保存（用于关键设置变更）
            performSave(settings)
        } else {
            // 防抖：取消之前的保存任务
            settingsSaveDebouncer?.cancel()

            // 创建新的延迟保存任务
            let task = DispatchWorkItem { [weak self] in
                guard let self = self,
                      let settings = self.pendingSettings else { return }
                self.performSave(settings)
                self.pendingSettings = nil
            }
            settingsSaveDebouncer = task

            // 延迟执行
            DispatchQueue.global(qos: .userInitiated).asyncAfter(
                deadline: .now() + debounceDelay,
                execute: task
            )

            Logger.debug("Settings save scheduled (debounced)", category: Logger.settings)
        }
    }

    /// 执行实际的保存操作
    private func performSave(_ settings: UserSettings) {
        Logger.measureTime(operation: "Save settings", category: Logger.performance) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(settings)
                userDefaults.set(data, forKey: settingsKey)

                // 在主线程更新 currentSettings
                DispatchQueue.main.async { [weak self] in
                    self?.currentSettings = settings
                }

                Logger.debug("Settings saved successfully", category: Logger.settings)
            } catch {
                Logger.error("Failed to encode settings", error: error, category: Logger.settings)
            }
        }
    }

    /// 立即保存所有待保存的设置（用于应用退出等场景）
    func flushPendingSettings() {
        if let settings = pendingSettings {
            settingsSaveDebouncer?.cancel()
            performSave(settings)
            pendingSettings = nil
        }
    }

    // MARK: - Update Individual Settings

    func updateMenuBarFormat(_ format: MenuBarFormat) {
        var updatedSettings = currentSettings
        updatedSettings.menuBarFormat = format
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
    }

    func updateShow24Hour(_ show24Hour: Bool) {
        var updatedSettings = currentSettings
        updatedSettings.show24Hour = show24Hour
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
    }

    func updateShowWeekday(_ showWeekday: Bool) {
        var updatedSettings = currentSettings
        updatedSettings.showWeekday = showWeekday
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
    }

    func updateWeekStartDay(_ weekStartDay: WeekStartDay) {
        var updatedSettings = currentSettings
        updatedSettings.weekStartDay = weekStartDay
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
        Logger.info("Week start day updated to '\(weekStartDay.displayName)'", category: Logger.settings)
    }

    func updateSecondaryCalendar(_ calendarType: CalendarType?) {
        let previousCalendar = currentSettings.secondaryCalendarType
        var updatedSettings = currentSettings
        updatedSettings.secondaryCalendarType = calendarType
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)

        // 如果日历类型发生变化且新类型不为空，发送通知触发推荐
        if let newCalendar = calendarType, previousCalendar != newCalendar {
            NotificationCenter.default.post(
                name: .calendarTypeDidChange,
                object: nil,
                userInfo: ["calendarType": newCalendar]
            )
            Logger.info("Calendar type changed to \(newCalendar.displayName), posting recommendation trigger", category: Logger.settings)
        }
    }

    // MARK: - Theme Settings

    /// 更新主题模式（浅色/自动/深色）
    func updateThemeMode(_ mode: ThemeMode) {
        var updatedSettings = currentSettings
        updatedSettings.themeMode = mode
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
        Logger.info("Theme mode updated to '\(mode.displayName)'", category: Logger.settings)
    }

    /// 更新浅色主题
    func updateLightTheme(_ themeId: String) {
        var updatedSettings = currentSettings
        updatedSettings.lightThemeId = themeId
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
        Logger.info("Light theme updated to '\(themeId)'", category: Logger.settings)
    }

    /// 更新深色主题
    func updateDarkTheme(_ themeId: String) {
        var updatedSettings = currentSettings
        updatedSettings.darkThemeId = themeId
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
        Logger.info("Dark theme updated to '\(themeId)'", category: Logger.settings)
    }

    /// 更新主题（已废弃，保留以兼容旧代码）
    @available(*, deprecated, message: "Use updateLightTheme() or updateDarkTheme() instead")
    func updateTheme(_ themeId: String) {
        var updatedSettings = currentSettings
        updatedSettings.themeId = themeId
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
    }

    func updateHoverSettings(enabled: Bool, delay: Double) {
        var updatedSettings = currentSettings
        updatedSettings.hoverToShowEnabled = enabled
        updatedSettings.hoverDelay = delay
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
    }

    // MARK: - Calendar Size Management

    /// 增大日历尺寸（切换到下一档位）
    func increaseCalendarSize() {
        let allSizes = CalendarSize.allCases
        guard let currentIndex = allSizes.firstIndex(of: currentSettings.calendarSize) else { return }

        // 如果已经是最大档位，不做变化
        guard currentIndex < allSizes.count - 1 else {
            Logger.info("Already at maximum calendar size", category: Logger.settings)
            return
        }

        let newSize = allSizes[currentIndex + 1]
        var updatedSettings = currentSettings
        updatedSettings.calendarSize = newSize
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
        Logger.info("Calendar size increased to \(newSize.displayName)", category: Logger.settings)
    }

    /// 减小日历尺寸（切换到上一档位）
    func decreaseCalendarSize() {
        let allSizes = CalendarSize.allCases
        guard let currentIndex = allSizes.firstIndex(of: currentSettings.calendarSize) else { return }

        // 如果已经是最小档位，不做变化
        guard currentIndex > 0 else {
            Logger.info("Already at minimum calendar size", category: Logger.settings)
            return
        }

        let newSize = allSizes[currentIndex - 1]
        var updatedSettings = currentSettings
        updatedSettings.calendarSize = newSize
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
        Logger.info("Calendar size decreased to \(newSize.displayName)", category: Logger.settings)
    }

    // MARK: - Reset Settings

    func resetToDefaults() {
        saveSettings(UserSettings.default)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let calendarTypeDidChange = Notification.Name("CalendarTypeDidChange")
    static let showOnboardingRequested = Notification.Name("ShowOnboardingRequested")
}
