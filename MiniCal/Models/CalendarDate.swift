//
//  CalendarDate.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import SwiftUI

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

    // 存储实际的 CalendarEvent 对象（非 Codable，用于运行时）
    var calendarEvents: [CalendarEvent] = []

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

    // MARK: - Event Indicator Properties

    /// 是否有事件
    var hasEvents: Bool {
        return !calendarEvents.isEmpty
    }

    /// 事件指示器颜色 - 取第一个事件的颜色（全天事件优先，然后按开始时间排序）
    var eventIndicatorColor: Color? {
        guard hasEvents else { return nil }

        // 排序规则：全天事件优先，然后按开始时间排序
        let sortedEvents = calendarEvents.sorted { event1, event2 in
            if event1.isAllDay != event2.isAllDay {
                return event1.isAllDay // 全天事件排前面
            }
            return event1.startDate < event2.startDate
        }

        return sortedEvents.first?.displayColor
    }

    /// 事件数量
    var eventCount: Int {
        return calendarEvents.count
    }
}
