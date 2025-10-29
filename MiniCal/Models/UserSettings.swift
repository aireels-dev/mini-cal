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

    /// 根据系统区域自动检测默认本地日历
    private static func detectDefaultCalendar() -> CalendarType? {
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? ""
        let languageCode = locale.language.languageCode?.identifier ?? ""

        Logger.info("Detecting default calendar - Region: \(regionCode), Language: \(languageCode)", category: Logger.settings)

        var detectedCalendar: CalendarType? = nil

        // 中国大陆、香港、澳门、台湾 -> 农历
        if regionCode == "CN" || regionCode == "HK" || regionCode == "MO" || regionCode == "TW" {
            detectedCalendar = .chinese
        }
        // 中文语言环境 -> 农历（兜底）
        else if languageCode.hasPrefix("zh") {
            detectedCalendar = .chinese
        }
        // 日本 -> 和历
        else if regionCode == "JP" || languageCode == "ja" {
            detectedCalendar = .japanese
        }
        // 伊斯兰国家/地区 -> 伊斯兰历
        else if ["SA", "AE", "IQ", "IR", "EG", "TR", "PK", "AF", "BD", "MY", "ID"].contains(regionCode) {
            detectedCalendar = .islamic
        }
        // 以色列 -> 希伯来历
        else if regionCode == "IL" || languageCode == "he" {
            detectedCalendar = .hebrew
        }
        // 伊朗 -> 波斯历
        else if regionCode == "IR" || languageCode == "fa" {
            detectedCalendar = .persian
        }
        // 泰国、缅甸、斯里兰卡等 -> 佛历
        else if ["TH", "MM", "LK", "KH", "LA"].contains(regionCode) {
            detectedCalendar = .buddhist
        }

        if let calendar = detectedCalendar {
            Logger.info("Auto-detected local calendar: \(calendar.displayName)", category: Logger.settings)
        } else {
            Logger.info("No matching local calendar for this region, defaulting to none", category: Logger.settings)
        }

        return detectedCalendar
    }
}
