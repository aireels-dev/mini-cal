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
    var lastUpdated: Date

    static let `default` = UserSettings(
        menuBarFormat: .dateTime,
        customFormat: "M月d日 HH:mm",
        show24Hour: false,
        showWeekday: false,
        showSeconds: false,
        secondaryCalendarType: nil,
        themeId: "system",
        hoverToShowEnabled: true,
        hoverDelay: 0.5,
        lastUpdated: Date()
    )
}
