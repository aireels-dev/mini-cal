//
//  ThemesIntegration.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI
import AppKit

// MARK: - Main Themes Integration

/// 主题系统集成入口点
struct ThemesIntegration {
    static func initialize() {
        // 初始化主题管理器
        _ = EnhancedThemeManager.shared

        // 设置全局主题环境
        setupGlobalThemeEnvironment()

        print("🎨 Enhanced Theme System initialized")
    }

    private static func setupGlobalThemeEnvironment() {
        // 设置全局主题相关的通知监听
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { notification in
            if let theme = notification.object as? ThemeConfiguration {
                updateGlobalAppearance(theme)
            }
        }
    }

    private static func updateGlobalAppearance(_ theme: ThemeConfiguration) {
        // 更新全局外观设置
        DispatchQueue.main.async {
            // 更新所有窗口的外观
            for window in NSApplication.shared.windows {
                window.appearance = NSAppearance(named: theme.category == .dark ? .darkAqua : .aqua)
            }
        }
    }
}

// MARK: - App Integration

extension NSApplication {
    /// 获取当前主题配置
    var currentTheme: ThemeConfiguration {
        return EnhancedThemeManager.shared.effectiveTheme
    }

    /// 应用主题到整个应用
    func applyTheme(_ theme: ThemeConfiguration) {
        EnhancedThemeManager.shared.applyTheme(theme, animated: true)
    }
}

// MARK: - Global Theme Access

/// 全局主题访问器
struct GlobalTheme {
    static var current: ThemeConfiguration {
        return EnhancedThemeManager.shared.effectiveTheme
    }

    static var manager: EnhancedThemeManager {
        return EnhancedThemeManager.shared
    }

    static var isDarkMode: Bool {
        return SystemAppearanceMonitor.shared.isDarkMode
    }
}

// MARK: - Theme-Aware Environment Key

struct ThemeConfigurationKey: EnvironmentKey {
    static let defaultValue = ThemeConfiguration.defaultLight
}

extension EnvironmentValues {
    var themeConfiguration: ThemeConfiguration {
        get { self[ThemeConfigurationKey.self] }
        set { self[ThemeConfigurationKey.self] = newValue }
    }
}