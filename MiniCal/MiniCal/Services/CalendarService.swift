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
    private let holidayProvider: HolidayProvider
    private let eventService: EventService

    init(
        secondaryCalendarConverter: SecondaryCalendarConverter = SecondaryCalendarConverter(),
        holidayProvider: HolidayProvider = HolidayProvider.shared,
        eventService: EventService = EventService.shared
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone.current
        self.gregorianCalendar = calendar
        self.secondaryCalendarConverter = secondaryCalendarConverter
        self.holidayProvider = holidayProvider
        self.eventService = eventService
    }

    // MARK: - Month Generation

    /// 生成指定月份的日历数据
    func generateMonth(for date: Date, secondaryCalendar: CalendarType? = nil) async -> [CalendarDate] {
        var dates: [Date] = []

        let monthStart = gregorianCalendar.firstDayOfMonth(for: date)
        let numberOfDaysInMonth = gregorianCalendar.numberOfDaysInMonth(for: date)
        let weekdayOfFirstDay = gregorianCalendar.weekdayOfFirstDay(for: date)

        // 计算需要显示的上个月的日期数量 (1=周日, 需要显示0天; 2=周一, 需要显示1天)
        let previousMonthDays = weekdayOfFirstDay - 1

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

        // 批量转换副日历信息（性能优化）
        var secondaryInfoMap: [Date: SecondaryDateInfo] = [:]
        if let calendarType = secondaryCalendar {
            secondaryInfoMap = secondaryCalendarConverter.batchConvert(dates: dates, to: calendarType)
        }

        // 获取节假日数据
        let year = gregorianCalendar.component(.year, from: date)
        let month = gregorianCalendar.component(.month, from: date)
        let monthHolidays = holidayProvider.getMonthHolidays(year: year, month: month, region: "CN")

        // 获取系统日历事件（重用已计算的monthStart）
        let monthEndDate = gregorianCalendar.lastDayOfMonth(for: date)
        let systemEvents = await eventService.fetchEvents(from: monthStart, to: monthEndDate)

        // 按日期分组系统事件
        var eventsMap: [String: [DateEvent]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for event in systemEvents {
            let dateString = dateFormatter.string(from: event.date)
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

            // 添加节假日事件
            let dateString = dateFormatter.string(from: dateValue)
            if let holiday = monthHolidays[dateString] {
                let holidayEvent = DateEvent(
                    title: holiday.name,
                    date: dateValue,
                    type: holiday.eventType,
                    source: .builtin,
                    description: holiday.name
                )
                calendarDate.events.append(holidayEvent)
            }

            // 添加系统日历事件
            if let dayEvents = eventsMap[dateString] {
                calendarDate.events.append(contentsOf: dayEvents)
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
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}
