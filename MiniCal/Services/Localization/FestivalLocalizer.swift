//
//  FestivalLocalizer.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation

/// 节日本地化器
class FestivalLocalizer {
    static let shared = FestivalLocalizer()

    private let localizationManager = LocalizationManager.shared

    // 节日数据缓存
    private var festivalDataCache: [String: FestivalData] = [:]
    private let cacheQueue = DispatchQueue(label: "com.minical.festival.cache")

    private init() {
        loadAllFestivalData()

        #if DEBUG
        // Debug 模式下验证节日数据
        validateFestivalData()
        #endif
    }

    // MARK: - Festival Localization

    /// 获取节日名称
    func festivalName(
        id: String,
        calendarType: CalendarType,
        locale: SupportedLocale? = nil
    ) -> String? {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale
        let cacheKey = festivalCacheKey(calendarType: calendarType, locale: effectiveLocale)

        guard let festivalData = getFestivalData(for: cacheKey) else {
            return nil
        }

        return festivalData.festivals[id]?.name
    }

    /// 获取所有节日（按日期索引）
    func festivals(
        for calendarType: CalendarType,
        locale: SupportedLocale? = nil
    ) -> [FestivalDate: String] {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale
        let cacheKey = festivalCacheKey(calendarType: calendarType, locale: effectiveLocale)

        guard let festivalData = getFestivalData(for: cacheKey) else {
            return [:]
        }

        var result: [FestivalDate: String] = [:]
        for (_, festival) in festivalData.festivals {
            let date = FestivalDate(month: festival.month, day: festival.day)
            result[date] = festival.name
        }

        return result
    }

    // MARK: - Solar Terms (二十四节气)

    /// 获取节气名称
    func solarTermName(
        order: Int,
        locale: SupportedLocale? = nil
    ) -> String? {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale
        let key = "solar_term_\(order)"
        let name = localizationManager.localized(key, table: "Festivals", locale: effectiveLocale)
        return name != key ? name : nil
    }

    // MARK: - Prayer Times

    /// 获取礼拜时间名称
    func prayerTimeName(
        _ prayerName: String,
        locale: SupportedLocale? = nil
    ) -> String {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale
        let key = "prayer_\(prayerName.lowercased())"
        return localizationManager.localized(key, table: "Festivals", locale: effectiveLocale)
    }

    // MARK: - Shabbat

    /// 获取安息日相关文本
    func shabbatText(
        key: String,
        locale: SupportedLocale? = nil
    ) -> String {
        let effectiveLocale = locale ?? localizationManager.context.effectiveCalendarLocale
        let fullKey = "shabbat_\(key)"
        return localizationManager.localized(fullKey, table: "Festivals", locale: effectiveLocale)
    }

    // MARK: - Data Loading

    private func loadAllFestivalData() {
        // 加载所有支持的历法和语言组合
        for calendarType in CalendarType.allCases {
            for locale in SupportedLocale.allCases {
                loadFestivalData(calendarType: calendarType, locale: locale)
            }
        }
    }

    private func loadFestivalData(
        calendarType: CalendarType,
        locale: SupportedLocale
    ) {
        let cacheKey = festivalCacheKey(calendarType: calendarType, locale: locale)

        // 获取数据文件路径
        guard let filePath = festivalDataFilePath(
            calendarType: calendarType,
            locale: locale
        ) else {
            return
        }

        // 加载 JSON 数据
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let festivalData = try JSONDecoder().decode(FestivalData.self, from: data)

            cacheQueue.async { [weak self] in
                self?.festivalDataCache[cacheKey] = festivalData
            }
        } catch {
            Logger.error("Failed to load festival data: \(filePath)", error: error, category: Logger.app)
        }
    }

    private func getFestivalData(for key: String) -> FestivalData? {
        return cacheQueue.sync {
            festivalDataCache[key]
        }
    }

    private func festivalCacheKey(
        calendarType: CalendarType,
        locale: SupportedLocale
    ) -> String {
        return "\(calendarType.rawValue)_\(locale.rawValue)"
    }

    private func festivalDataFilePath(
        calendarType: CalendarType,
        locale: SupportedLocale
    ) -> String? {
        let fileName: String

        switch calendarType {
        case .chinese:
            fileName = "Chinese_Festivals_\(locale.rawValue).json"
        case .islamic:
            fileName = "Islamic_Festivals_\(locale.rawValue).json"
        case .hebrew:
            fileName = "Hebrew_Holidays_\(locale.rawValue).json"
        case .persian:
            fileName = "Persian_Festivals_\(locale.rawValue).json"
        case .japanese:
            fileName = "Japanese_Festivals_\(locale.rawValue).json"
        case .buddhist:
            fileName = "Buddhist_Festivals_\(locale.rawValue).json"
        case .gregorian:
            return nil  // 公历节日由系统处理
        }

        let subdir = calendarType.rawValue.capitalized
        return Bundle.main.path(
            forResource: fileName.replacingOccurrences(of: ".json", with: ""),
            ofType: "json",
            inDirectory: "CalendarData/\(subdir)"
        )
    }

    // MARK: - Data Validation (Debug Only)

    #if DEBUG
    /// 验证节日数据完整性（仅在 Debug 模式下运行）
    private func validateFestivalData() {
        Logger.debug("Starting festival data validation...", category: Logger.app)

        var missingDataCount = 0
        var invalidIDCount = 0
        var totalFestivals = 0

        for calendarType in CalendarType.allCases where calendarType != .gregorian {
            for locale in SupportedLocale.allCases {
                let cacheKey = festivalCacheKey(calendarType: calendarType, locale: locale)

                guard let festivalData = getFestivalData(for: cacheKey) else {
                    missingDataCount += 1
                    Logger.warning(
                        "Missing festival data: \(calendarType.rawValue) - \(locale.rawValue)",
                        category: Logger.app
                    )
                    continue
                }

                // 验证每个节日的 ID
                for (key, festival) in festivalData.festivals {
                    totalFestivals += 1

                    // 检查 ID 是否为空或无效
                    if festival.id.isEmpty {
                        invalidIDCount += 1
                        Logger.warning(
                            "Invalid festival ID (empty): \(key) in \(calendarType.rawValue) - \(locale.rawValue)",
                            category: Logger.app
                        )
                    }

                    // 检查 ID 是否与 key 一致（推荐规范）
                    if festival.id != key {
                        Logger.debug(
                            "Festival ID mismatch: key=\(key), id=\(festival.id) in \(calendarType.rawValue) - \(locale.rawValue)",
                            category: Logger.app
                        )
                    }

                    // 检查月份日期是否有效
                    if festival.month < 1 || festival.month > 13 {
                        Logger.warning(
                            "Invalid month: \(festival.month) for \(festival.id) in \(calendarType.rawValue)",
                            category: Logger.app
                        )
                    }

                    if festival.day < 1 || festival.day > 31 {
                        Logger.warning(
                            "Invalid day: \(festival.day) for \(festival.id) in \(calendarType.rawValue)",
                            category: Logger.app
                        )
                    }
                }
            }
        }

        // 输出验证总结
        Logger.info(
            """
            Festival data validation completed:
            - Total festivals: \(totalFestivals)
            - Missing data files: \(missingDataCount)
            - Invalid IDs: \(invalidIDCount)
            """,
            category: Logger.app
        )

        if missingDataCount > 0 || invalidIDCount > 0 {
            Logger.warning(
                "Festival data validation found issues. Please check CalendarData/ directory.",
                category: Logger.app
            )
        }
    }
    #endif
}

// MARK: - Festival Data Models

struct FestivalData: Codable {
    let festivals: [String: Festival]

    struct Festival: Codable {
        let id: String
        let name: String
        let month: Int
        let day: Int
        let importance: Importance?

        enum Importance: String, Codable {
            case major
            case minor
        }
    }
}

struct FestivalDate: Hashable {
    let month: Int
    let day: Int
}
