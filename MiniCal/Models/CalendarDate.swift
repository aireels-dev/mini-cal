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

    // 统一的事件存储 - 使用 CalendarEvent 模型
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
        // calendarEvents 默认为空数组
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

        return sortedEvents.first?.getDisplayColor()
    }

    /// 事件数量
    var eventCount: Int {
        return calendarEvents.count
    }

    /// 获取多个事件的颜色（用于指示器显示）
    var eventColors: [EventColor] {
        // 排序规则：全天事件优先，然后按开始时间排序
        let sortedEvents = calendarEvents.sorted { event1, event2 in
            if event1.isAllDay != event2.isAllDay {
                return event1.isAllDay
            }
            return event1.startDate < event2.startDate
        }

        // 转换为 EventColor（从显示颜色映射）
        return sortedEvents.map { event in
            colorToEventColor(event.getDisplayColor())
        }
    }

    /// 辅助方法：将 SwiftUI Color 转换为 EventColor 枚举（优化版本）
    private func colorToEventColor(_ color: Color) -> EventColor {
        // 注意：由于 Color 无法直接比较，我们使用颜色的描述字符串
        let colorString = String(describing: color).lowercased()

        // 映射系统预定义颜色（按优先级排序）
        if colorString.contains("blue") { return .blue }
        if colorString.contains("red") { return .red }
        if colorString.contains("green") { return .green }
        if colorString.contains("orange") { return .orange }
        if colorString.contains("purple") { return .purple }
        if colorString.contains("pink") { return .pink }
        if colorString.contains("yellow") { return .yellow }
        if colorString.contains("gray") { return .gray }
        if colorString.contains("teal") { return .teal }
        if colorString.contains("indigo") { return .indigo }
        if colorString.contains("mint") { return .mint }
        if colorString.contains("cyan") { return .cyan }
        if colorString.contains("brown") { return .brown }

        // 默认返回蓝色
        return .blue
    }
}
