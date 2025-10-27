//
//  UserSettings.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct UserSettings: Codable {
    var menuBarFormat: MenuBarFormat
    var show24Hour: Bool
    var showWeekday: Bool
    var secondaryCalendarType: CalendarType?
    var themeId: String
    var hoverToShowEnabled: Bool
    var hoverDelay: Double
    var lastUpdated: Date

    static let `default` = UserSettings(
        menuBarFormat: .dateTime,
        show24Hour: false,
        showWeekday: false,
        secondaryCalendarType: nil,
        themeId: "system",
        hoverToShowEnabled: true,
        hoverDelay: 0.5,
        lastUpdated: Date()
    )
}
