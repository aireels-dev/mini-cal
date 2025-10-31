//
//  UserPreferences.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import Foundation
import SwiftUI
import Combine

// MARK: - User Preferences Storage

/// 用户主题偏好设置存储管理器
class UserPreferencesStorage: ObservableObject {
    @Published private var storageKey: String = "com.minical.theme.preferences"

    // 添加ObservableObject要求的属性
    let objectWillChange = ObjectWillChangePublisher()
    static let shared = UserPreferencesStorage()

    private let userDefaultsKey = "com.minical.theme.preferences"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Save and Load

    /// 保存用户偏好设置
    func savePreferences(_ preferences: UserThemePreferences) -> Bool {
        do {
            let data = try encoder.encode(preferences)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            return true
        } catch {
            print("Failed to save theme preferences: \(error)")
            return false
        }
    }

    /// 加载用户偏好设置
    func loadPreferences() -> UserThemePreferences {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return UserThemePreferences()
        }

        do {
            return try decoder.decode(UserThemePreferences.self, from: data)
        } catch {
            print("Failed to load theme preferences: \(error)")
            // 尝试从损坏的数据中恢复
            return recoverFromCorruptedData()
        }
    }

    // MARK: - Migration

    /// 从损坏的数据中恢复偏好设置
    private func recoverFromCorruptedData() -> UserThemePreferences {
        var preferences = UserThemePreferences()

        // 尝试恢复部分设置
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let partialPreferences = try? decoder.decode(
                PartialUserThemePreferences.self,
                from: data
            ) {
                preferences.mode = partialPreferences.mode ?? .auto
                if let lightId = partialPreferences.lightThemeId, !lightId.isEmpty {
                    preferences.lightThemeId = lightId
                }
                if let darkId = partialPreferences.darkThemeId, !darkId.isEmpty {
                    preferences.darkThemeId = darkId
                }
            }
        }

        return preferences
    }

    /// 迁移旧版本偏好设置
    func migratePreferences(from oldVersion: String, to newVersion: String) -> UserThemePreferences {
        var preferences = loadPreferences()

        // 根据版本进行迁移
        switch (oldVersion, newVersion) {
        case ("1.0", "1.1"):
            // 添加新的设置字段
            if preferences.customSettings.isEmpty {
                preferences.customSettings = [:]
            }

        case ("1.1", "2.0"):
            // 重构主题ID格式
            preferences.lightThemeId = migrateThemeId(preferences.lightThemeId)
            preferences.darkThemeId = migrateThemeId(preferences.darkThemeId)

        default:
            break
        }

        preferences.lastUsedVersion = newVersion
        _ = savePreferences(preferences)
        return preferences
    }

    private func migrateThemeId(_ oldId: String) -> String {
        let migrationMap = [
            "blue": "classic_blue",
            "green": "fresh_green",
            "dark_blue": "midnight_blue",
            "orange": "sunset_orange",
            "red": "ruby_red",
            "gray": "graphite_gray"
        ]
        return migrationMap[oldId] ?? oldId
    }

    // MARK: - Validation

    /// 验证偏好设置的有效性
    func validatePreferences(_ preferences: UserThemePreferences) -> [ValidationError] {
        var errors: [ValidationError] = []

        // 检查主题ID是否有效
        if preferences.lightThemeId.isEmpty {
            errors.append(ValidationError(
                field: "lightThemeId",
                message: "白天主题ID不能为空"
            ))
        }

        if preferences.darkThemeId.isEmpty {
            errors.append(ValidationError(
                field: "darkThemeId",
                message: "黑夜主题ID不能为空"
            ))
        }

        return errors
    }
}

// MARK: - Partial Preferences for Recovery

/// 部分用户偏好设置（用于数据恢复）
private struct PartialUserThemePreferences: Codable {
    var mode: ThemeMode?
    var lightThemeId: String?
    var darkThemeId: String?
    var enableRealTimePreview: Bool?
    var enableSmoothTransitions: Bool?
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private static let themePreferencesKey = "com.minical.theme.preferences"

    /// 便捷的偏好设置访问属性
    var themePreferences: UserThemePreferences {
        get {
            return UserPreferencesStorage.shared.loadPreferences()
        }
        set {
            UserPreferencesStorage.shared.savePreferences(newValue)
        }
    }
}

// MARK: - Theme Preferences Manager

/// 主题偏好设置管理器（与主题管理器集成）
class ThemePreferencesManager: ObservableObject {
    @Published var preferences: UserThemePreferences = UserThemePreferences()

    // 添加ObservableObject要求的属性
    let objectWillChange = ObjectWillChangePublisher()

    private let storage = UserPreferencesStorage.shared

    init() {
        loadPreferences()
    }

    // MARK: - Load and Save

    func loadPreferences() {
        preferences = storage.loadPreferences()
        validateAndFixPreferences()
    }

    func savePreferences() {
        guard storage.validatePreferences(preferences).isEmpty else {
            print("Failed to save preferences: validation errors")
            return
        }

        if storage.savePreferences(preferences) {
            print("Theme preferences saved successfully")
        }
    }

    // MARK: - Preference Updates

    func updateMode(_ mode: ThemeMode) {
        preferences.mode = mode
        savePreferences()
    }

    func updateLightTheme(_ themeId: String) {
        preferences.lightThemeId = themeId
        savePreferences()
    }

    func updateDarkTheme(_ themeId: String) {
        preferences.darkThemeId = themeId
        savePreferences()
    }

    func updateRealTimePreview(_ enabled: Bool) {
        preferences.enableRealTimePreview = enabled
        savePreferences()
    }

    func updateSmoothTransitions(_ enabled: Bool) {
        preferences.enableSmoothTransitions = enabled
        savePreferences()
    }

    // MARK: - Validation and Fix

    private func validateAndFixPreferences() {
        var needsSave = false

        // 修复无效的主题ID
        if preferences.lightThemeId.isEmpty {
            preferences.lightThemeId = ThemeCategory.light.defaultThemes.first!
            needsSave = true
        }

        if preferences.darkThemeId.isEmpty {
            preferences.darkThemeId = ThemeCategory.dark.defaultThemes.first!
            needsSave = true
        }

        // 修复版本号
        if preferences.lastUsedVersion.isEmpty {
            preferences.lastUsedVersion = "1.0"
            needsSave = true
        }

        if needsSave {
            savePreferences()
        }
    }

    // MARK: - Reset

    func resetToDefaults() {
        preferences = UserThemePreferences()
        savePreferences()
    }
}