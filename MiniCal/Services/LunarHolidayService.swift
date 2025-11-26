//
//  LunarHolidayService.swift
//  MiniCal
//
//  lunar-swift 节日数据服务
//  区分公历节日（全局显示）和农历节日（仅农历时显示）
//

import Foundation
import LunarSwift

class LunarHolidayService {
    static let shared = LunarHolidayService()

    private init() {}

    // MARK: - Public Methods

    /// 获取公历节日（西方节日，所有历法都显示）
    /// - Parameter date: 公历日期
    /// - Returns: 节日名称数组
    func getSolarFestivals(for date: Date) -> [String] {
        let solar = Solar.fromDate(date: date)
        return solar.festivals
    }

    /// 获取农历节日（中国传统节日，仅农历时显示）
    /// - Parameter date: 公历日期
    /// - Returns: 节日名称数组
    func getLunarFestivals(for date: Date) -> [String] {
        let solar = Solar.fromDate(date: date)
        let lunar = solar.lunar
        return lunar.festivals
    }

    /// 获取其他节日（纪念日等）
    /// - Parameter date: 公历日期
    /// - Returns: 节日名称数组
    func getOtherFestivals(for date: Date) -> [String] {
        let solar = Solar.fromDate(date: date)
        return solar.otherFestivals
    }

    /// 获取完整的节日信息（用于调试或全量显示）
    /// - Parameters:
    ///   - date: 公历日期
    ///   - includeOther: 是否包含其他节日
    /// - Returns: 所有节日的合并数组
    func getAllFestivals(for date: Date, includeOther: Bool = false) -> [String] {
        var festivals: [String] = []

        // 公历节日
        festivals.append(contentsOf: getSolarFestivals(for: date))

        // 农历节日
        festivals.append(contentsOf: getLunarFestivals(for: date))

        // 其他节日
        if includeOther {
            festivals.append(contentsOf: getOtherFestivals(for: date))
        }

        return festivals
    }

    /// 获取首要显示的节日（优先级：农历节日 > 公历节日 > 其他）
    /// - Parameter date: 公历日期
    /// - Returns: 首要节日名称
    func getPrimaryFestival(for date: Date) -> String? {
        // 优先显示农历传统节日
        let lunarFestivals = getLunarFestivals(for: date)
        if let first = lunarFestivals.first {
            return first
        }

        // 其次显示公历节日
        let solarFestivals = getSolarFestivals(for: date)
        if let first = solarFestivals.first {
            return first
        }

        // 最后显示其他节日
        let otherFestivals = getOtherFestivals(for: date)
        return otherFestivals.first
    }

    // MARK: - Lunar Calendar Information

    /// 获取农历详细信息
    /// - Parameter date: 公历日期
    /// - Returns: Lunar 对象
    func getLunarInfo(for date: Date) -> Lunar {
        let solar = Solar.fromDate(date: date)
        return solar.lunar
    }

    /// 获取生肖
    /// - Parameter date: 公历日期
    /// - Returns: 生肖名称
    func getZodiac(for date: Date) -> String {
        let lunar = getLunarInfo(for: date)
        return lunar.yearShengXiao
    }

    /// 获取干支纪年
    /// - Parameter date: 公历日期
    /// - Returns: 干支字符串
    func getGanZhi(for date: Date) -> String {
        let lunar = getLunarInfo(for: date)
        return "\(lunar.yearInGanZhi)年"
    }
}
