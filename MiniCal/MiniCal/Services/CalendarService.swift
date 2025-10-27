//
//  CalendarService.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

class CalendarService {
    private let gregorianCalendar: Calendar

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone.current
        self.gregorianCalendar = calendar
    }

    // MARK: - Month Generation

    /// 生成指定月份的日历数据
    func generateMonth(for date: Date, secondaryCalendar: CalendarType? = nil) -> [CalendarDate] {
        var dates: [CalendarDate] = []

        let monthStart = gregorianCalendar.firstDayOfMonth(for: date)
        let numberOfDaysInMonth = gregorianCalendar.numberOfDaysInMonth(for: date)
        let weekdayOfFirstDay = gregorianCalendar.weekdayOfFirstDay(for: date)

        // 计算需要显示的上个月的日期数量 (1=周日, 需要显示0天; 2=周一, 需要显示1天)
        let previousMonthDays = weekdayOfFirstDay - 1

        // 添加上个月的日期
        if previousMonthDays > 0, let previousMonthStart = gregorianCalendar.date(byAdding: .day, value: -previousMonthDays, to: monthStart) {
            for dayOffset in 0..<previousMonthDays {
                if let dayDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: previousMonthStart) {
                    dates.append(createCalendarDate(from: dayDate, isCurrentMonth: false, secondaryCalendar: secondaryCalendar))
                }
            }
        }

        // 添加当月的日期
        for day in 0..<numberOfDaysInMonth {
            if let dayDate = gregorianCalendar.date(byAdding: .day, value: day, to: monthStart) {
                dates.append(createCalendarDate(from: dayDate, isCurrentMonth: true, secondaryCalendar: secondaryCalendar))
            }
        }

        // 添加下个月的日期，填充到6行 (42天)
        let remainingDays = 42 - dates.count
        if remainingDays > 0 {
            let lastDayOfMonth = gregorianCalendar.date(byAdding: .day, value: numberOfDaysInMonth - 1, to: monthStart)!
            let nextMonthStart = gregorianCalendar.date(byAdding: .day, value: 1, to: lastDayOfMonth)!
            for dayOffset in 0..<remainingDays {
                if let dayDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: nextMonthStart) {
                    dates.append(createCalendarDate(from: dayDate, isCurrentMonth: false, secondaryCalendar: secondaryCalendar))
                }
            }
        }

        return dates
    }

    // MARK: - Calendar Date Creation

    private func createCalendarDate(from date: Date, isCurrentMonth: Bool, secondaryCalendar: CalendarType?) -> CalendarDate {
        // 使用 CalendarDate 的默认初始化器
        var calendarDate = CalendarDate(date: date, isCurrentMonth: isCurrentMonth)

        // 添加副历信息
        if let calendarType = secondaryCalendar {
            calendarDate.secondaryDate = generateSecondaryDate(for: date, calendarType: calendarType)
        }

        return calendarDate
    }

    // MARK: - Secondary Calendar

    private func generateSecondaryDate(for date: Date, calendarType: CalendarType) -> SecondaryDateInfo? {
        guard let identifier = calendarType.identifier else { return nil }

        var secondaryCalendar = Calendar(identifier: identifier)
        secondaryCalendar.locale = Locale(identifier: "zh_CN")

        let components = secondaryCalendar.dateComponents([.year, .month, .day], from: date)

        let displayText: String
        switch calendarType {
        case .chinese:
            // 农历显示格式
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.calendar = secondaryCalendar
            formatter.dateFormat = "MMMd"
            displayText = formatter.string(from: date)
        case .islamic, .hebrew, .persian, .japanese, .buddhist:
            // 其他日历简单显示月/日
            if let month = components.month, let day = components.day {
                displayText = "\(month)/\(day)"
            } else {
                displayText = ""
            }
        case .gregorian:
            return nil
        }

        return SecondaryDateInfo(
            calendarType: calendarType,
            displayText: displayText,
            year: components.year,
            month: components.month,
            day: components.day,
            festival: nil
        )
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
