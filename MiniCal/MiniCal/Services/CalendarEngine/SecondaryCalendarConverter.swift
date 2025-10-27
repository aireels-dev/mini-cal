//
//  SecondaryCalendarConverter.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

class SecondaryCalendarConverter {

    // MARK: - Single Date Conversion

    /// 将公历日期转换为指定副日历类型
    func convert(gregorianDate: Date, to calendarType: CalendarType) -> SecondaryDateInfo? {
        guard let identifier = calendarType.identifier else { return nil }

        var calendar = Calendar(identifier: identifier)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone.current

        let components = calendar.dateComponents([.year, .month, .day], from: gregorianDate)

        let displayText = formatDisplayText(
            for: gregorianDate,
            calendarType: calendarType,
            calendar: calendar,
            components: components
        )

        // 检查是否为节日
        let festival = getFestivalName(for: gregorianDate, calendarType: calendarType)

        return SecondaryDateInfo(
            calendarType: calendarType,
            displayText: displayText,
            year: components.year,
            month: components.month,
            day: components.day,
            festival: festival
        )
    }

    // MARK: - Batch Conversion

    /// 批量转换日期，提高性能
    func batchConvert(dates: [Date], to calendarType: CalendarType) -> [Date: SecondaryDateInfo] {
        var result: [Date: SecondaryDateInfo] = [:]

        for date in dates {
            if let info = convert(gregorianDate: date, to: calendarType) {
                result[date] = info
            }
        }

        return result
    }

    // MARK: - Display Text Formatting

    private func formatDisplayText(
        for date: Date,
        calendarType: CalendarType,
        calendar: Calendar,
        components: DateComponents
    ) -> String {
        switch calendarType {
        case .chinese:
            return formatChineseDate(date: date, calendar: calendar)

        case .buddhist:
            // 佛历 = 公历年 + 543
            if let year = components.year, let month = components.month, let day = components.day {
                let buddhistYear = year + 543
                return "\(month)/\(day)"
            }
            return ""

        case .islamic:
            return formatIslamicDate(components: components)

        case .hebrew:
            return formatHebrewDate(components: components)

        case .persian:
            return formatPersianDate(components: components)

        case .japanese:
            return formatJapaneseDate(components: components)

        case .gregorian:
            return ""
        }
    }

    // MARK: - Chinese Calendar Formatting

    private func formatChineseDate(date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = calendar
        formatter.dateFormat = "MMMd" // 例如: "正月初一"

        let text = formatter.string(from: date)

        // 简化显示：去除"月"字，保留关键信息
        let simplified = text
            .replacingOccurrences(of: "正月", with: "正")
            .replacingOccurrences(of: "二月", with: "二")
            .replacingOccurrences(of: "三月", with: "三")
            .replacingOccurrences(of: "四月", with: "四")
            .replacingOccurrences(of: "五月", with: "五")
            .replacingOccurrences(of: "六月", with: "六")
            .replacingOccurrences(of: "七月", with: "七")
            .replacingOccurrences(of: "八月", with: "八")
            .replacingOccurrences(of: "九月", with: "九")
            .replacingOccurrences(of: "十月", with: "十")
            .replacingOccurrences(of: "冬月", with: "冬")
            .replacingOccurrences(of: "腊月", with: "腊")

        return simplified
    }

    private func formatIslamicDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }
        return "\(month)/\(day)"
    }

    private func formatHebrewDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }
        return "\(month)/\(day)"
    }

    private func formatPersianDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }
        return "\(month)/\(day)"
    }

    private func formatJapaneseDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }
        return "\(month)/\(day)"
    }

    // MARK: - Festival Detection

    /// 识别节日名称
    func getFestivalName(for date: Date, calendarType: CalendarType) -> String? {
        switch calendarType {
        case .chinese:
            return getChineseFestival(for: date)
        case .islamic:
            return getIslamicFestival(for: date)
        case .hebrew:
            return getHebrewFestival(for: date)
        default:
            return nil
        }
    }

    private func getChineseFestival(for date: Date) -> String? {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 主要农历节日
        switch (month, day) {
        case (1, 1):
            return "春节"
        case (1, 15):
            return "元宵"
        case (5, 5):
            return "端午"
        case (7, 7):
            return "七夕"
        case (8, 15):
            return "中秋"
        case (9, 9):
            return "重阳"
        case (12, 8):
            return "腊八"
        default:
            return nil
        }
    }

    private func getIslamicFestival(for date: Date) -> String? {
        var calendar = Calendar(identifier: .islamicCivil)
        calendar.locale = Locale(identifier: "zh_CN")

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 主要伊斯兰节日
        switch (month, day) {
        case (9, 1):
            return "斋月开始"
        case (10, 1):
            return "开斋节"
        case (12, 10):
            return "宰牲节"
        default:
            return nil
        }
    }

    private func getHebrewFestival(for date: Date) -> String? {
        var calendar = Calendar(identifier: .hebrew)
        calendar.locale = Locale(identifier: "zh_CN")

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 主要犹太节日
        switch (month, day) {
        case (1, 1), (1, 2):
            return "犹太新年"
        case (1, 10):
            return "赎罪日"
        case (7, 15):
            return "光明节"
        default:
            return nil
        }
    }
}
