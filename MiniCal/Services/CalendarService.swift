//
//  CalendarService.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

class CalendarService {
    private let gregorianCalendar: Calendar
    private let secondaryCalendarConverter: SecondaryCalendarConverter
    private let unifiedEventService: UnifiedEventService
    private let settingsManager: SettingsManager

    init(
        secondaryCalendarConverter: SecondaryCalendarConverter = SecondaryCalendarConverter(),
        unifiedEventService: UnifiedEventService = UnifiedEventService.shared,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone.current
        self.gregorianCalendar = calendar
        self.secondaryCalendarConverter = secondaryCalendarConverter
        self.unifiedEventService = unifiedEventService
        self.settingsManager = settingsManager
    }

    // MARK: - Month Generation

    /// 生成指定月份的日历数据
    func generateMonth(for date: Date, secondaryCalendar: CalendarType? = nil) async -> [CalendarDate] {
        var dates: [Date] = []

        let monthStart = gregorianCalendar.firstDayOfMonth(for: date)
        let numberOfDaysInMonth = gregorianCalendar.numberOfDaysInMonth(for: date)

        // 获取用户设置的每周起始日
        let weekStartDay = settingsManager.currentSettings.weekStartDay

        // 计算需要显示的上个月的日期数量（基于每周起始日设置）
        let previousMonthDays = gregorianCalendar.previousMonthDays(for: date, weekStartDay: weekStartDay)

        // 收集所有需要显示的日期
        // 添加上个月的日期
        if previousMonthDays > 0, let previousMonthStart = gregorianCalendar.date(byAdding: .day, value: -previousMonthDays, to: monthStart) {
            for dayOffset in 0..<previousMonthDays {
                if let dayDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: previousMonthStart) {
                    dates.append(dayDate)
                }
            }
        }

        // 添加当月的日期
        for day in 0..<numberOfDaysInMonth {
            if let dayDate = gregorianCalendar.date(byAdding: .day, value: day, to: monthStart) {
                dates.append(dayDate)
            }
        }

        // 添加下个月的日期，填充到6行 (42天)
        let remainingDays = 42 - dates.count
        if remainingDays > 0 {
            let lastDayOfMonth = gregorianCalendar.date(byAdding: .day, value: numberOfDaysInMonth - 1, to: monthStart)!
            let nextMonthStart = gregorianCalendar.date(byAdding: .day, value: 1, to: lastDayOfMonth)!
            for dayOffset in 0..<remainingDays {
                if let dayDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: nextMonthStart) {
                    dates.append(dayDate)
                }
            }
        }

        // 批量转换本地历法信息（性能优化）
        var secondaryInfoMap: [Date: SecondaryDateInfo] = [:]
        if let calendarType = secondaryCalendar {
            secondaryInfoMap = secondaryCalendarConverter.batchConvert(dates: dates, to: calendarType)
        }

        // 获取所有事件（系统+外部订阅+本地）使用统一事件服务
        // 注意：节假日数据现在通过外部订阅获取，不再从本地 JSON 加载
        // 重要：获取实际显示范围内的所有事件（包括非当月日期）
        guard let displayStartDate = dates.first,
              let displayEndDate = dates.last else {
            Logger.error("Failed to get display date range", category: Logger.calendar)
            return []
        }

        let allEvents: [CalendarEvent]
        do {
            // 使用实际显示的日期范围，包括上月末尾和下月开头
            allEvents = try await unifiedEventService.getEvents(in: DateRange(startDate: displayStartDate, endDate: displayEndDate))
            Logger.debug("📅 Loaded \(allEvents.count) events from UnifiedEventService (including non-current month dates)", category: Logger.calendar)
        } catch {
            Logger.error("Failed to load events from UnifiedEventService: \(error)", category: Logger.calendar)
            allEvents = []
        }

        // 按日期分组事件
        var eventsMap: [String: [CalendarEvent]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for event in allEvents {
            let dateString = dateFormatter.string(from: event.startDate)
            eventsMap[dateString, default: []].append(event)
        }

        // 创建 CalendarDate 对象（重用已计算的monthStart）
        var calendarDates: [CalendarDate] = []

        for dateValue in dates {
            let isCurrentMonth = gregorianCalendar.isDate(dateValue, equalTo: monthStart, toGranularity: .month)
            var calendarDate = CalendarDate(date: dateValue, isCurrentMonth: isCurrentMonth)

            // 添加副历信息
            if let secondaryInfo = secondaryInfoMap[dateValue] {
                calendarDate.secondaryDate = secondaryInfo
            }

            // 添加所有事件（系统日历、外部订阅、本地事件）
            let dateString = dateFormatter.string(from: dateValue)
            if let dayEvents = eventsMap[dateString] {
                calendarDate.calendarEvents.append(contentsOf: dayEvents)
                Logger.debug("  ✅ Added \(dayEvents.count) events on \(dateString)", category: Logger.calendar)
            }

            calendarDates.append(calendarDate)
        }

        return calendarDates
    }

    // MARK: - Navigation Helpers

    /// 获取上个月的日期
    func previousMonth(from date: Date) -> Date {
        return gregorianCalendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    /// 获取下个月的日期
    func nextMonth(from date: Date) -> Date {
        return gregorianCalendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// 获取今天的日期
    func today() -> Date {
        return Date()
    }

    // MARK: - Month/Year Info

    /// 获取月份和年份的显示文本
    func monthYearText(for date: Date) -> String {
        let formatter = DateFormatter()
        let localeId = LocalizationManager.shared.context.effectiveInterfaceLocale.rawValue
        formatter.locale = Locale(identifier: localeId)
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMM", options: 0, locale: Locale(identifier: localeId))
        return formatter.string(from: date)
    }
}
