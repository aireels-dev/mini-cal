//
//  MoonPhaseService.swift
//  MiniCal
//
//  月相计算服务
//

import Foundation

class MoonPhaseService {
    static let shared = MoonPhaseService()

    private init() {}

    // MARK: - Moon Phase Enum

    enum MoonPhase: String, CaseIterable {
        case newMoon = "新月"
        case waxingCrescent = "娥眉月"
        case firstQuarter = "上弦月"
        case waxingGibbous = "盈凸月"
        case fullMoon = "满月"
        case waningGibbous = "亏凸月"
        case lastQuarter = "下弦月"
        case waningCrescent = "残月"

        var emoji: String {
            switch self {
            case .newMoon: return "🌑"
            case .waxingCrescent: return "🌒"
            case .firstQuarter: return "🌓"
            case .waxingGibbous: return "🌔"
            case .fullMoon: return "🌕"
            case .waningGibbous: return "🌖"
            case .lastQuarter: return "🌗"
            case .waningCrescent: return "🌘"
            }
        }

        var description: String {
            switch self {
            case .newMoon: return "朔月"
            case .waxingCrescent: return "上蛾眉月"
            case .firstQuarter: return "上弦月"
            case .waxingGibbous: return "渐盈凸月"
            case .fullMoon: return "望月"
            case .waningGibbous: return "渐亏凸月"
            case .lastQuarter: return "下弦月"
            case .waningCrescent: return "下蛾眉月"
            }
        }
    }

    // MARK: - Public Methods

    /// 获取指定日期的月相
    /// - Parameter date: 日期
    /// - Returns: 月相枚举
    func getMoonPhase(for date: Date) -> MoonPhase {
        let phase = calculateMoonPhase(for: date)

        switch phase {
        case 0..<0.0625: return .newMoon
        case 0.0625..<0.1875: return .waxingCrescent
        case 0.1875..<0.3125: return .firstQuarter
        case 0.3125..<0.4375: return .waxingGibbous
        case 0.4375..<0.5625: return .fullMoon
        case 0.5625..<0.6875: return .waningGibbous
        case 0.6875..<0.8125: return .lastQuarter
        case 0.8125..<1.0: return .waningCrescent
        default: return .newMoon
        }
    }

    /// 获取月相照亮百分比
    /// - Parameter date: 日期
    /// - Returns: 照亮百分比 (0.0 - 1.0)
    func getMoonIllumination(for date: Date) -> Double {
        let phase = calculateMoonPhase(for: date)

        // 从新月到满月：0 -> 0.5，照亮度从 0 -> 1
        // 从满月到新月：0.5 -> 1.0，照亮度从 1 -> 0
        if phase < 0.5 {
            return phase * 2.0
        } else {
            return 2.0 - (phase * 2.0)
        }
    }

    /// 获取月龄（从新月开始的天数）
    /// - Parameter date: 日期
    /// - Returns: 月龄（0-29天）
    func getMoonAge(for date: Date) -> Double {
        let phase = calculateMoonPhase(for: date)
        let synodicMonth = 29.530588  // 朔望月周期（天）
        return phase * synodicMonth
    }

    // MARK: - Private Methods

    /// 计算月相周期位置
    /// - Parameter date: 日期
    /// - Returns: 月相位置 (0.0 - 1.0)，0.0 = 新月，0.5 = 满月
    private func calculateMoonPhase(for date: Date) -> Double {
        // 参考新月时间：2000年1月6日 18:14 UTC
        let referenceNewMoon = Date(timeIntervalSince1970: 947182440) // 2000-01-06 18:14:00 UTC
        let synodicMonth = 29.530588 * 86400.0  // 朔望月周期（秒）

        let elapsed = date.timeIntervalSince(referenceNewMoon)
        let phase = elapsed.truncatingRemainder(dividingBy: synodicMonth) / synodicMonth

        return phase
    }

    /// 获取下一个特定月相的日期
    /// - Parameters:
    ///   - targetPhase: 目标月相
    ///   - date: 起始日期
    /// - Returns: 下一个目标月相的日期
    func getNextPhaseDate(targetPhase: MoonPhase, from date: Date) -> Date? {
        let synodicMonth = 29.530588 * 86400.0  // 秒

        // 当前月相周期位置
        let currentPhaseValue = calculateMoonPhase(for: date)

        // 目标月相的周期位置
        let targetPhaseValue: Double
        switch targetPhase {
        case .newMoon: targetPhaseValue = 0.0
        case .waxingCrescent: targetPhaseValue = 0.125
        case .firstQuarter: targetPhaseValue = 0.25
        case .waxingGibbous: targetPhaseValue = 0.375
        case .fullMoon: targetPhaseValue = 0.5
        case .waningGibbous: targetPhaseValue = 0.625
        case .lastQuarter: targetPhaseValue = 0.75
        case .waningCrescent: targetPhaseValue = 0.875
        }

        // 计算到下一个目标月相的时间差
        var phaseDifference = targetPhaseValue - currentPhaseValue
        if phaseDifference < 0 {
            phaseDifference += 1.0
        }

        let timeToNextPhase = phaseDifference * synodicMonth
        return date.addingTimeInterval(timeToNextPhase)
    }
}
