//
//  SolarTermService.swift
//  MiniCal
//
//  二十四节气计算服务
//

import Foundation

class SolarTermService {
    static let shared = SolarTermService()

    private init() {}

    // MARK: - Public Methods

    /// 查询指定日期的节气
    /// - Parameter date: 公历日期
    /// - Returns: 节气名称，如果不是节气则返回 nil
    func getSolarTerm(for date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        // 遍历所有节气，使用寿星公式计算精确日期
        for solarTerm in SolarTerm.allSolarTerms {
            if let termDate = calculateSolarTermDateByShouXing(
                year: year,
                solarTerm: solarTerm
            ) {
                let termComponents = calendar.dateComponents([.year, .month, .day], from: termDate)

                // 精确匹配：年月日完全相同才显示节气
                if year == termComponents.year,
                   month == termComponents.month,
                   day == termComponents.day {
                    return solarTerm.name
                }
            }
        }

        return nil
    }

    /// 判断是否为节气名称
    func isSolarTerm(_ name: String) -> Bool {
        return SolarTerm.allSolarTerms.contains(where: { $0.name == name })
    }

    /// 获取指定月份的所有节气
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 节气字典 [Date: 节气名称]
    func getSolarTermsForMonth(year: Int, month: Int) -> [Date: String] {
        var result: [Date: String] = [:]
        let calendar = Calendar.current

        for solarTerm in SolarTerm.allSolarTerms {
            // 使用寿星公式计算精确日期
            if let termDate = calculateSolarTermDateByShouXing(
                year: year,
                solarTerm: solarTerm
            ) {
                let components = calendar.dateComponents([.month], from: termDate)

                // 确认计算出的日期确实在目标月份
                if components.month == month {
                    result[termDate] = solarTerm.name
                }
            }
        }

        return result
    }

    /// 获取下一个节气
    func getNextSolarTerm(from date: Date) -> (name: String, date: Date)? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        // 获取当年和下一年的所有节气日期，使用寿星公式
        var allTermDates: [(String, Date)] = []

        for targetYear in [year, year + 1] {
            for solarTerm in SolarTerm.allSolarTerms {
                if let termDate = calculateSolarTermDateByShouXing(
                    year: targetYear,
                    solarTerm: solarTerm
                ) {
                    allTermDates.append((solarTerm.name, termDate))
                }
            }
        }

        // 找到下一个节气
        let futurTerms = allTermDates.filter { $0.1 > date }.sorted { $0.1 < $1.1 }
        return futurTerms.first
    }

    // MARK: - Private Methods

    /// 使用寿星公式计算指定节气的精确日期
    ///
    /// 寿星公式是一个经过天文学验证的24节气计算公式，适用于1900-2100年。
    /// 公式：D = [Y × 0.2422 + C] - L
    ///
    /// 参数说明：
    /// - D: 节气的日期（天数）
    /// - Y: 年份的后两位数（例如2025年取25）
    /// - C: 节气在特定世纪的常数（每个节气、每个世纪都有专属常数）
    /// - L: 闰年修正值，计算公式为 [(Y-1)/4] 向下取整
    ///
    /// 误差范围：±1天以内（极少数情况）
    ///
    /// - Parameters:
    ///   - year: 公历年份（1900-2100）
    ///   - solarTerm: 节气对象
    /// - Returns: 精确的节气日期，如果年份超出范围则返回 nil
    private func calculateSolarTermDateByShouXing(year: Int, solarTerm: SolarTerm) -> Date? {
        // 1月的节气（小寒、大寒）属于上一年的节气周期
        let calculationYear = (solarTerm.approximateMonth == 1) ? year - 1 : year

        // 确定使用哪个世纪的常数
        let century = calculationYear / 100
        let C: Double
        if century == 19 {
            C = solarTerm.century20C
        } else if century == 20 {
            C = solarTerm.century21C
        } else {
            // 超出范围（1900-2100）
            return nil
        }

        // 年份后两位
        let Y = calculationYear % 100

        // 闰年修正：L = [(Y-1)/4]
        let L = (Y - 1) / 4

        // 寿星公式：D = [Y * 0.2422 + C] - L
        let D = Int(floor(Double(Y) * 0.2422 + C)) - L

        // 构建日期
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year  // 使用传入的年份
        components.month = solarTerm.approximateMonth
        components.day = D

        return calendar.date(from: components)
    }

}
