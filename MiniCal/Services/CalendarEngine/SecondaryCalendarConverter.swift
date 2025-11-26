//
//  SecondaryCalendarConverter.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import CoreLocation
import LunarSwift

class SecondaryCalendarConverter {

    // MARK: - Calendar Recommendation

    /// 根据系统区域推荐合适的本地历法类型
    /// - Parameter locale: 系统区域设置
    /// - Returns: 推荐的本地历法类型，如果无匹配则返回 nil
    static func recommendCalendar(for locale: Locale) -> CalendarType? {
        let regionCode = locale.region?.identifier ?? ""
        let languageCode = locale.language.languageCode?.identifier ?? ""

        // 中国大陆、香港、澳门、台湾 -> 农历
        if regionCode == "CN" || regionCode == "HK" || regionCode == "MO" || regionCode == "TW" {
            return .chinese
        }
        // 中文语言环境 -> 农历（兜底）
        else if languageCode.hasPrefix("zh") {
            return .chinese
        }
        // 日本 -> 和历
        else if regionCode == "JP" || languageCode == "ja" {
            return .japanese
        }
        // 伊斯兰国家/地区 -> 伊斯兰历
        else if ["SA", "AE", "IQ", "IR", "EG", "TR", "PK", "AF", "BD", "MY", "ID"].contains(regionCode) {
            return .islamic
        }
        // 以色列 -> 希伯来历
        else if regionCode == "IL" || languageCode == "he" {
            return .hebrew
        }
        // 伊朗 -> 波斯历（注意：伊朗可能匹配伊斯兰历或波斯历，优先波斯历）
        else if regionCode == "IR" || languageCode == "fa" {
            return .persian
        }
        // 泰国、缅甸、斯里兰卡等 -> 佛历
        else if ["TH", "MM", "LK", "KH", "LA"].contains(regionCode) {
            return .buddhist
        }

        // 其他地区不自动推荐
        return nil
    }

    // MARK: - Single Date Conversion

    /// 将公历日期转换为指定本地历法类型
    /// - Parameters:
    ///   - gregorianDate: 公历日期
    ///   - calendarType: 目标历法类型
    ///   - location: 地理位置（可选，用于计算礼拜时间和安息日）
    /// - Returns: 副历日期信息
    func convert(
        gregorianDate: Date,
        to calendarType: CalendarType,
        location: CLLocationCoordinate2D? = nil
    ) -> SecondaryDateInfo? {
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

        // 检查是否为节日（包括节气）
        let festival = getFestivalName(for: gregorianDate, calendarType: calendarType)

        // 获取公历节日（全局显示，使用 lunar-swift）
        let solarFestival = getSolarFestivalName(for: gregorianDate)

        // 计算礼拜时间信息（仅伊斯兰历）
        var prayerInfo: PrayerInfo? = nil
        if calendarType == .islamic, let location = location {
            if let prayerTimes = PrayerTimeService.shared.calculatePrayerTimes(
                for: gregorianDate,
                location: location
            ) {
                if let nextPrayer = prayerTimes.getNextPrayer(from: gregorianDate) {
                    prayerInfo = PrayerInfo(
                        nextPrayerName: nextPrayer.name,
                        nextPrayerTime: nextPrayer.time
                    )
                }
            }
        }

        // 计算安息日信息（仅希伯来历）
        var shabbatDisplayInfo: ShabbatDisplayInfo? = nil
        if calendarType == .hebrew, let location = location {
            let shabbatInfo = ShabbatService.shared.getShabbatInfo(for: gregorianDate, location: location)
            if shabbatInfo.isShabbatDay {
                shabbatDisplayInfo = ShabbatDisplayInfo(
                    isShabbat: shabbatInfo.isShabbat,
                    shabbatStart: shabbatInfo.shabbatStart,
                    shabbatEnd: shabbatInfo.shabbatEnd
                )
            }
        }

        return SecondaryDateInfo(
            calendarType: calendarType,
            displayText: displayText,
            year: components.year,
            month: components.month,
            day: components.day,
            festival: festival,
            solarFestival: solarFestival,
            nextPrayerInfo: prayerInfo,
            shabbatDisplayInfo: shabbatDisplayInfo
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
        // 1. 优先检查二十四节气（优先级最高）
        if let solarTerm = SolarTermService.shared.getSolarTerm(for: date) {
            return solarTerm
        }

        // 2. 使用 lunar-swift 获取农历节日
        let lunarFestivals = LunarHolidayService.shared.getLunarFestivals(for: date)
        return lunarFestivals.first
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
        // 1. 检查使用 ShabbatService 的犹太节日
        if let holiday = ShabbatService.shared.getJewishHoliday(for: date) {
            return holiday
        }

        // 2. 检查农历节日（补充）
        var calendar = Calendar(identifier: .hebrew)
        calendar.locale = Locale(identifier: "zh_CN")

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 其他犹太节日（ShabbatService 中未包含的）
        switch (month, day) {
        default:
            return nil
        }
    }

    /// 获取公历节日（全局显示，使用 lunar-swift）
    /// - Parameter date: 公历日期
    /// - Returns: 公历节日名称
    private func getSolarFestivalName(for date: Date) -> String? {
        let solarFestivals = LunarHolidayService.shared.getSolarFestivals(for: date)
        return solarFestivals.first
    }
}
