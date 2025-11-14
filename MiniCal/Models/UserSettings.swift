//
//  UserSettings.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct UserSettings: Codable, Equatable {
    var menuBarFormat: MenuBarFormat
    var customFormat: String
    var show24Hour: Bool
    var showWeekday: Bool
    var showSeconds: Bool
    var secondaryCalendarType: CalendarType?

    // MARK: - 主题设置

    /// 主题模式（浅色/自动/深色）
    var themeMode: ThemeMode

    /// 浅色模式下的主题ID
    var lightThemeId: String

    /// 深色模式下的主题ID
    var darkThemeId: String

    /// 兼容旧版本：当前主题ID（已废弃，保留用于迁移）
    var themeId: String?

    /// 日历浮窗不透明度（0.0 - 1.0）
    var calendarOpacity: Double

    // MARK: - 全局快捷键设置

    /// 是否启用全局快捷键
    /// 注意：实际快捷键由 KeyboardShortcuts 库管理，存储在独立的 UserDefaults key 中
    var globalHotkeyEnabled: Bool

    // MARK: - 系统设置

    /// 开机自动启动
    var launchAtLogin: Bool

    // MARK: - 其他设置

    var hoverToShowEnabled: Bool
    var hoverDelay: Double
    var calendarSize: CalendarSize
    var lastUpdated: Date

    static let `default` = UserSettings(
        menuBarFormat: .dateTime,
        customFormat: "M月d日 HH:mm",
        show24Hour: false,
        showWeekday: false,
        showSeconds: false,
        secondaryCalendarType: detectDefaultCalendar(),
        themeMode: .auto,
        lightThemeId: "classic_blue",
        darkThemeId: "midnight_blue",
        themeId: nil,
        calendarOpacity: 0.5,
        globalHotkeyEnabled: true,
        launchAtLogin: true,
        hoverToShowEnabled: true,
        hoverDelay: 0.5,
        calendarSize: .standard,
        lastUpdated: Date()
    )

    /// 根据系统区域自动检测默认本地历法
    /// 使用 SecondaryCalendarConverter 的推荐逻辑
    private static func detectDefaultCalendar() -> CalendarType? {
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? ""
        let languageCode = locale.language.languageCode?.identifier ?? ""

        Logger.info("Detecting default calendar - Region: \(regionCode), Language: \(languageCode)", category: Logger.settings)

        let detectedCalendar = SecondaryCalendarConverter.recommendCalendar(for: locale)

        if let calendar = detectedCalendar {
            Logger.info("Auto-detected local calendar: \(calendar.displayName)", category: Logger.settings)
        } else {
            Logger.info("No matching local calendar for this region, defaulting to none", category: Logger.settings)
        }

        return detectedCalendar
    }
}
