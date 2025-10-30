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
    var themeId: String
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
        themeId: "system",
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
