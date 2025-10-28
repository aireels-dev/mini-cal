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
                let _ = year + 543  // buddhistYear计算保留用于未来扩展
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
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let day = components.day else { return "" }

        // 如果是每月初一，显示月份
        if day == 1 {
            let monthFormatter = DateFormatter()
            monthFormatter.locale = Locale(identifier: "zh_CN")
            monthFormatter.calendar = calendar
            monthFormatter.dateFormat = "MMM" // 月份：正月、二月...腊月
            return monthFormatter.string(from: date)
        }

        // 其他日期转换为中文表达（初二、初三...廿九、三十）
        return convertChineseDayToText(day: day)
    }

    /// 将农历日期数字转换为中文表达
    /// - Parameter day: 日期数字 (1-30)
    /// - Returns: 中文表达（如：初一、初二、十一、廿一、三十）
    private func convertChineseDayToText(day: Int) -> String {
        switch day {
        case 1...10:
            // 初一到初十
            let dayTexts = ["", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十"]
            return dayTexts[day]
        case 11...19:
            // 十一到十九
            let dayTexts = ["", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九"]
            return dayTexts[day - 10]
        case 20:
            return "二十"
        case 21...29:
            // 廿一到廿九
            let dayTexts = ["", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九"]
            return dayTexts[day - 20]
        case 30:
            return "三十"
        default:
            return "\(day)"
        }
    }

    private func formatIslamicDate(components: DateComponents) -> String {
        guard let day = components.day else { return "" }

        // 每月初一显示月份名称，其他日期仅显示日期
        if day == 1 {
            return CalendarMonthNames.getIslamicMonthName(components.month, short: true)
        }
        return "\(day)"
    }

    private func formatHebrewDate(components: DateComponents) -> String {
        guard let day = components.day else { return "" }

        // 每月初一显示月份名称，其他日期仅显示日期
        if day == 1 {
            return CalendarMonthNames.getHebrewMonthName(components.month, short: true)
        }
        return "\(day)"
    }

    private func formatPersianDate(components: DateComponents) -> String {
        guard let day = components.day else { return "" }

        // 每月初一显示月份名称，其他日期仅显示日期
        if day == 1 {
            return CalendarMonthNames.getPersianMonthName(components.month, short: true)
        }
        return "\(day)"
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
