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

    func saveSettings(_ settings: UserSettings) {
        Logger.measureTime(operation: "Save settings", category: Logger.performance) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(settings)
                userDefaults.set(data, forKey: settingsKey)
                currentSettings = settings
                Logger.debug("Settings saved successfully", category: Logger.settings)
            } catch {
                Logger.error("Failed to encode settings", error: error, category: Logger.settings)
            }
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

    func updateSecondaryCalendar(_ calendarType: CalendarType?) {
        var updatedSettings = currentSettings
        updatedSettings.secondaryCalendarType = calendarType
        updatedSettings.lastUpdated = Date()
        saveSettings(updatedSettings)
    }

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

    // MARK: - Reset Settings

    func resetToDefaults() {
        saveSettings(UserSettings.default)
    }
}
