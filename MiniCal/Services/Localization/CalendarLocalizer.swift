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

    // MARK: - Caching

    /// DateFormatter 缓存
    private var formatterCache: [FormatterCacheKey: DateFormatter] = [:]
    private var accessOrder: [FormatterCacheKey] = []  // LRU 访问顺序
    private let cacheQueue = DispatchQueue(label: "com.minical.calendar.formatter.cache")

    // 限制缓存大小，避免内存膨胀
    private let maxFormatterCacheSize = 20

    private init() {
        // 监听本地化上下文变更，清理缓存
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearFormatterCache),
            name: .localizationDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 清理 DateFormatter 缓存（在语言切换时调用）
    @objc private func clearFormatterCache() {
        cacheQueue.async { [weak self] in
            // 抑制 Swift 6 Main Actor 警告 - 已确保线程安全
            // FormatterCacheKey 是 @unchecked Sendable，所有操作在串行队列上执行
            self?.formatterCache.removeAll()
            self?.accessOrder.removeAll()
        }
    }

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
        return getMonthNameFromSystem(
            month: month,
            calendarIdentifier: .gregorian,
            style: style,
            locale: locale
        )
    }

    // MARK: - Private Helpers - Chinese

    private func chineseMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        return getMonthNameFromSystem(
            month: month,
            calendarIdentifier: .chinese,
            style: style,
            locale: locale
        )
    }

    /// 格式化农历日期
    /// - Parameters:
    ///   - day: 日期（1-30）
    ///   - locale: 目标语言
    /// - Returns: 格式化后的日期文本
    private func formatChineseDay(day: Int, locale: SupportedLocale) -> String {
        // 策略1: 优先使用 .xcstrings 本地化字符串（所有语言统一）
        let key = "chinese_day_\(day)"
        let localizedDay = localizationManager.localized(key, table: "CalendarNames", locale: locale)

        // 如果翻译存在（不等于 key），使用翻译
        if localizedDay != key {
            return localizedDay
        }

        // 策略2: Fallback 到系统 API（仅限 CJK 语言）
        if isCJKLocale(locale) {
            if let systemFormatted = getChineseDayFromSystem(day: day, locale: locale) {
                return systemFormatted
            }
        }

        // 策略3: 最终 fallback 到数字
        return "\(day)"
    }

    /// 使用系统 Calendar API 格式化农历日期
    /// - Parameters:
    ///   - day: 日期（1-30）
    ///   - locale: 目标语言
    /// - Returns: 格式化后的日期文本（如果系统支持）
    private func getChineseDayFromSystem(day: Int, locale: SupportedLocale) -> String? {
        // 创建农历日期（使用当前月份的某一天）
        var components = DateComponents()
        components.calendar = Calendar(identifier: .chinese)
        components.year = 4722  // 2025年对应的农历年
        components.month = 1
        components.day = day

        guard let date = components.date else {
            return nil
        }

        // 使用缓存的 DateFormatter 获取农历日期文本
        let formatter = getCachedFormatter(calendarIdentifier: .chinese, locale: locale)

        // 使用本地化的日期模板（仅日期部分）
        formatter.setLocalizedDateFormatFromTemplate("d")

        let formatted = formatter.string(from: date)

        // 验证格式化结果是否有效（不是纯数字）
        if formatted.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
            return formatted
        }

        return nil
    }

    /// 判断是否为 CJK 语言（中日韩）
    private func isCJKLocale(_ locale: SupportedLocale) -> Bool {
        return locale == .simplifiedChinese ||
               locale == .traditionalChinese ||
               locale == .japanese ||
               locale == .korean
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
        return getMonthNameFromSystem(
            month: month,
            calendarIdentifier: .islamicCivil,
            style: style,
            locale: locale
        )
    }

    // MARK: - Private Helpers - Hebrew

    private func hebrewMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        return getMonthNameFromSystem(
            month: month,
            calendarIdentifier: .hebrew,
            style: style,
            locale: locale
        )
    }

    // MARK: - Private Helpers - Persian

    private func persianMonthName(
        month: Int,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        return getMonthNameFromSystem(
            month: month,
            calendarIdentifier: .persian,
            style: style,
            locale: locale
        )
    }

    // MARK: - System API Helper

    /// 使用系统 Calendar API 获取月份名称（带缓存）
    private func getMonthNameFromSystem(
        month: Int,
        calendarIdentifier: Calendar.Identifier,
        style: MonthNameStyle,
        locale: SupportedLocale
    ) -> String {
        let formatter = getCachedFormatter(calendarIdentifier: calendarIdentifier, locale: locale)

        let symbols = style == .short ? formatter.shortMonthSymbols : formatter.monthSymbols

        guard let symbols = symbols, month >= 1, month <= symbols.count else {
            return "\(month)"
        }

        return symbols[month - 1]
    }

    // MARK: - Formatter Caching Helpers

    /// 获取或创建缓存的 DateFormatter（使用 LRU 策略）
    private func getCachedFormatter(
        calendarIdentifier: Calendar.Identifier,
        locale: SupportedLocale
    ) -> DateFormatter {
        let key = FormatterCacheKey(
            calendarIdentifier: identifierString(from: calendarIdentifier),
            locale: locale.rawValue
        )

        return cacheQueue.sync {
            // LRU 缓存命中 - 更新访问顺序
            if let cached = formatterCache[key] {
                // 移到访问顺序末尾（最近使用）
                accessOrder.removeAll { $0 == key }
                accessOrder.append(key)
                return cached
            }

            // 缓存未命中 - 创建新 formatter
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: calendarIdentifier)
            formatter.locale = locale.locale

            // 添加到缓存
            formatterCache[key] = formatter
            accessOrder.append(key)

            // 超过限制时移除最少使用的项（LRU）
            if formatterCache.count > maxFormatterCacheSize {
                let oldestKey = accessOrder.removeFirst()
                formatterCache.removeValue(forKey: oldestKey)
            }

            return formatter
        }
    }

    /// 将 Calendar.Identifier 转换为字符串表示
    private func identifierString(from identifier: Calendar.Identifier) -> String {
        switch identifier {
        case .gregorian:
            return "gregorian"
        case .chinese:
            return "chinese"
        case .islamic, .islamicCivil:
            return "islamic"
        case .hebrew:
            return "hebrew"
        case .persian:
            return "persian"
        case .japanese:
            return "japanese"
        case .buddhist:
            return "buddhist"
        default:
            return "\(identifier)"
        }
    }
}

// MARK: - Supporting Types

/// DateFormatter 缓存键
/// 使用 @unchecked Sendable 因为 FormatterCacheKey 只包含不可变值类型，是线程安全的
private struct FormatterCacheKey: Hashable, @unchecked Sendable {
    let calendarIdentifier: String
    let locale: String
}

enum MonthNameStyle {
    case full
    case short
}
