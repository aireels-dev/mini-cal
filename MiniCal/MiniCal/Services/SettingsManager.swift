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
        self.currentSettings = UserSettings.default
        self.currentSettings = loadSettings()
    }

    // MARK: - Load Settings

    func loadSettings() -> UserSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return UserSettings.default
        }

        do {
            let decoder = JSONDecoder()
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
