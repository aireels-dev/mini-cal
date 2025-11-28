//
//  CalendarLocalizer.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation

/// 历法本地化器
class CalendarLocalizer {
    static let shared = CalendarLocalizer()

    private let localizationManager = LocalizationManager.shared

    private init() {}

    // MARK: - Calendar Names

    /// 获取历法类型的本地化名称
    func calendarTypeName(_ calendarType: CalendarType) -> String {
        let key = "calendar_type_\(calendarType.rawValue)"
        // 日历类型名称应该跟随界面语言，而不是历法语言
        return localizationManager.localized(key, table: "CalendarNames", locale: localizationManager.context.effectiveInterfaceLocale)
    }

    // MARK: - Month Names

    /// 获取月份名称
    func monthName(
        month: Int,
        calendarType: CalendarType,
        style: MonthNameStyle = .full,
        locale: SupportedLocale? = nil
    ) -> String {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale

        switch calendarType {
        case .gregorian:
            return gregorianMonthName(month: month, style: style, locale: effectiveLocale)
        case .chinese:
            return chineseMonthName(month: month, style: style, locale: effectiveLocale)
        case .islamic:
            return islamicMonthName(month: month, style: style, locale: effectiveLocale)
        case .hebrew:
            return hebrewMonthName(month: month, style: style, locale: effectiveLocale)
        case .persian:
            return persianMonthName(month: month, style: style, locale: effectiveLocale)
        case .japanese:
            return gregorianMonthName(month: month, style: style, locale: effectiveLocale)
        case .buddhist:
            return gregorianMonthName(month: month, style: style, locale: effectiveLocale)
        }
    }

    // MARK: - Day Formatting

    /// 格式化日期文本
    func formatDay(
        day: Int,
        calendarType: CalendarType,
        locale: SupportedLocale? = nil
    ) -> String {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale

        switch calendarType {
        case .chinese:
            return formatChineseDay(day: day, locale: effectiveLocale)
        default:
            return "\(day)"
        }
    }

    // MARK: - Zodiac Animals

    /// 获取生肖动物名称
    func zodiacAnimal(
        year: Int,
        locale: SupportedLocale? = nil
    ) -> String {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale

        // 越南使用猫代替兔子
        let isVietnamese = effectiveLocale == .vietnamese

        let animals: [String]
        if isVietnamese {
            animals = getVietnameseZodiacAnimals(locale: effectiveLocale)
        } else {
            animals = getChineseZodiacAnimals(locale: effectiveLocale)
        }

        let index = (year - 4) % 12
        let safeIndex = index >= 0 ? index : index + 12
        return animals[safeIndex]
    }

    // MARK: - Private Helpers - Gregorian

    private func gregorianMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        let key = style == .short ? "gregorian_month_short_\(month)" : "gregorian_month_\(month)"
        return localizationManager.localized(key, table: "CalendarNames", locale: locale)
    }

    // MARK: - Private Helpers - Chinese

    private func chineseMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        let key = style == .short ? "chinese_month_short_\(month)" : "chinese_month_\(month)"
        return localizationManager.localized(key, table: "CalendarNames", locale: locale)
    }

    private func formatChineseDay(day: Int, locale: SupportedLocale) -> String {
        // 对于简中、繁中使用传统表达
        if locale == .simplifiedChinese || locale == .traditionalChinese {
            return convertChineseDayToText(day: day)
        }

        // 其他语言使用数字
        return "\(day)"
    }

    private func convertChineseDayToText(day: Int) -> String {
        switch day {
        case 1...10:
            let dayTexts = ["", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十"]
            return dayTexts[day]
        case 11...19:
            let dayTexts = ["", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九"]
            return dayTexts[day - 10]
        case 20:
            return "二十"
        case 21...29:
            let dayTexts = ["", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九"]
            return dayTexts[day - 20]
        case 30:
            return "三十"
        default:
            return "\(day)"
        }
    }

    private func getChineseZodiacAnimals(locale: SupportedLocale) -> [String] {
        return (0..<12).map { index in
            let key = "zodiac_animal_\(index)"
            return localizationManager.localized(key, table: "CalendarNames", locale: locale)
        }
    }

    private func getVietnameseZodiacAnimals(locale: SupportedLocale) -> [String] {
        return (0..<12).map { index in
            let key = "zodiac_animal_vietnamese_\(index)"
            return localizationManager.localized(key, table: "CalendarNames", locale: locale)
        }
    }

    // MARK: - Private Helpers - Islamic

    private func islamicMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        let key = style == .short ? "islamic_month_short_\(month)" : "islamic_month_\(month)"
        return localizationManager.localized(key, table: "CalendarNames", locale: locale)
    }

    // MARK: - Private Helpers - Hebrew

    private func hebrewMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        let key = style == .short ? "hebrew_month_short_\(month)" : "hebrew_month_\(month)"
        return localizationManager.localized(key, table: "CalendarNames", locale: locale)
    }

    // MARK: - Private Helpers - Persian

    private func persianMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        let key = style == .short ? "persian_month_short_\(month)" : "persian_month_\(month)"
        return localizationManager.localized(key, table: "CalendarNames", locale: locale)
    }
}

// MARK: - Month Name Style

enum MonthNameStyle {
    case full
    case short
}
