//
//  ThemeModels.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Theme Mode

/// 定义主题的应用方式（黑夜/白天/自动）
enum ThemeMode: String, CaseIterable, Codable {
    case light    // 强制白天模式
    case dark     // 强制黑夜模式
    case auto     // 跟随系统外观

    var displayName: String {
        switch self {
        case .light: return "白天模式"
        case .dark: return "黑夜模式"
        case .auto: return "自动模式"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .auto: return "circle.lefthalf.filled"
        }
    }

    var description: String {
        switch self {
        case .light: return "始终使用浅色主题"
        case .dark: return "始终使用深色主题"
        case .auto: return "跟随系统外观设置"
        }
    }

    var systemColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil // 使用系统设置
        }
    }
}

// MARK: - Theme Category

/// 主题分类（白天/黑夜）
enum ThemeCategory: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .light: return "白天主题"
        case .dark: return "黑夜主题"
        }
    }

    var defaultThemes: [String] {
        switch self {
        case .light:
            return ["classic_blue", "fresh_green", "sunset_orange", "ocean_teal", "lavender_purple"]
        case .dark:
            return ["midnight_blue", "forest_green", "ruby_red", "graphite_gray", "deep_purple"]
        }
    }
}

// MARK: - User Theme Preferences

/// 用户主题偏好设置
struct UserThemePreferences: Codable {
    var mode: ThemeMode = .auto
    var lightThemeId: String = "classic_blue"
    var darkThemeId: String = "midnight_blue"
    var enableRealTimePreview: Bool = true
    var enableSmoothTransitions: Bool = true
    var lastUsedVersion: String = "1.0"

    // 扩展配置
    var customSettings: [String: String] = [:]

    init() {
        self.lightThemeId = ThemeCategory.light.defaultThemes.first!
        self.darkThemeId = ThemeCategory.dark.defaultThemes.first!
    }
}

// MARK: - Theme Preview State

/// 主题预览状态管理
class ThemePreviewState: ObservableObject {
    @Published var isPreviewing: Bool = false
    @Published var previewThemeId: String?
    @Published var originalThemeId: String?

    func startPreview(themeId: String, originalThemeId: String) {
        self.previewThemeId = themeId
        self.originalThemeId = originalThemeId
        self.isPreviewing = true
    }

    func stopPreview() {
        self.isPreviewing = false
        self.previewThemeId = nil
        self.originalThemeId = nil
    }
}