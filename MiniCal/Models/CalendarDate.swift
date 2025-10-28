//
//  CalendarDate.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct CalendarDate: Identifiable, Codable, Equatable {
    let id: UUID
    let gregorianDate: Date
    let year: Int
    let month: Int
    let day: Int
    let weekday: Int
    var secondaryDate: SecondaryDateInfo?
    var isToday: Bool
    var isCurrentMonth: Bool
    var events: [DateEvent]

    init(date: Date, isCurrentMonth: Bool = true) {
        self.id = UUID()
        self.gregorianDate = date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        self.year = components.year!
        self.month = components.month!
        self.day = components.day!
        self.weekday = components.weekday!
        self.isToday = calendar.isDateInToday(date)
        self.isCurrentMonth = isCurrentMonth
        self.events = []
    }
}
