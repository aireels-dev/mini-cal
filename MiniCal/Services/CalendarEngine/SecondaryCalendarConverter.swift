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

    private let calendarLocalizer = CalendarLocalizer.shared
    private let festivalLocalizer = FestivalLocalizer.shared
    private let localizationManager = LocalizationManager.shared

    // MARK: - Calendar Recommendation

    /// 根据系统区域推荐合适的本地历法类型
    /// - Parameter locale: 系统区域设置
    /// - Returns: 推荐的本地历法类型，如果无匹配则返回 nil
    static func recommendCalendar(for locale: Locale) -> CalendarType? {
        let regionCode = locale.regionCodeIdentifier
        let languageCode = locale.languageCodeIdentifier

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
        // 使用当前本地化上下文的语言环境
        let currentLocale = localizationManager.context.effectiveCalendarLocale
        calendar.locale = currentLocale.locale
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
            festivalID: nil,  // TODO: 实现节日 ID 获取逻辑
            solarFestival: solarFestival,
            solarFestivalID: nil,  // TODO: 实现公历节日 ID 获取逻辑
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
        guard let month = components.month, let day = components.day else { return "" }

        // 如果是每月初一，显示月份
        if day == 1 {
            return calendarLocalizer.monthName(month: month, calendarType: .chinese, style: .full)
        }

        // 其他日期使用本地化格式
        return calendarLocalizer.formatDay(day: day, calendarType: .chinese)
    }

    private func formatIslamicDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }

        // 每月初一显示月份名称，其他日期仅显示日期
        if day == 1 {
            return calendarLocalizer.monthName(month: month, calendarType: .islamic, style: .short)
        }
        return "\(day)"
    }

    private func formatHebrewDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }

        // 每月初一显示月份名称，其他日期仅显示日期
        if day == 1 {
            return calendarLocalizer.monthName(month: month, calendarType: .hebrew, style: .short)
        }
        return "\(day)"
    }

    private func formatPersianDate(components: DateComponents) -> String {
        guard let month = components.month, let day = components.day else { return "" }

        // 每月初一显示月份名称，其他日期仅显示日期
        if day == 1 {
            return calendarLocalizer.monthName(month: month, calendarType: .persian, style: .short)
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
        calendar.locale = localizationManager.context.effectiveCalendarLocale.locale

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 使用本地化节日数据库查找节日
        let allFestivals = festivalLocalizer.festivals(for: .islamic)
        let festivalDate = FestivalDate(month: month, day: day)
        return allFestivals[festivalDate]
    }

    private func getHebrewFestival(for date: Date) -> String? {
        var calendar = Calendar(identifier: .hebrew)
        calendar.locale = localizationManager.context.effectiveCalendarLocale.locale

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 使用本地化节日数据库查找节日
        let allFestivals = festivalLocalizer.festivals(for: .hebrew)
        let festivalDate = FestivalDate(month: month, day: day)
        return allFestivals[festivalDate]
    }

    /// 获取公历节日（全局显示，使用 lunar-swift）
    /// - Parameter date: 公历日期
    /// - Returns: 公历节日名称
    private func getSolarFestivalName(for date: Date) -> String? {
        let solarFestivals = LunarHolidayService.shared.getSolarFestivals(for: date)
        return solarFestivals.first
    }
}
