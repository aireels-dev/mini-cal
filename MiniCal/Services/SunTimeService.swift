//
//  SunTimeService.swift
//  MiniCal
//
//  日出日落时间计算服务
//  依赖：Solar 库 (https://github.com/ceeK/Solar)
//

import Foundation
import CoreLocation
import Solar

class SunTimeService {
    static let shared = SunTimeService()

    private init() {}

    // MARK: - Sun Times Structure

    struct SunTimes {
        let sunrise: Date       // 日出时间
        let sunset: Date        // 日落时间
        let solarNoon: Date     // 正午时间（太阳最高点）
        let civilDawn: Date?    // 民用晨光始（太阳在地平线下6°）
        let civilDusk: Date?    // 民用昏影终
        let nauticalDawn: Date? // 航海晨光始（太阳在地平线下12°）
        let nauticalDusk: Date? // 航海昏影终
        let astronomicalDawn: Date?  // 天文晨光始（太阳在地平线下18°）
        let astronomicalDusk: Date?  // 天文昏影终
        let dayLength: TimeInterval  // 白昼时长（秒）

        /// 格式化白昼时长
        var formattedDayLength: String {
            let hours = Int(dayLength / 3600)
            let minutes = Int((dayLength.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)小时\(minutes)分钟"
        }
    }

    // MARK: - Public Methods

    /// 计算指定日期和位置的日出日落时间
    /// - Parameters:
    ///   - date: 日期
    ///   - location: 地理位置坐标
    /// - Returns: 日出日落时间信息，如果计算失败返回 nil
    func calculate(for date: Date, location: CLLocationCoordinate2D) -> SunTimes? {
        // 使用 Solar 库进行精确计算
        guard let solar = Solar(for: date, coordinate: location) else {
            Logger.warning("Solar 计算失败", category: Logger.app)
            return nil
        }

        guard let sunrise = solar.sunrise,
              let sunset = solar.sunset else {
            Logger.warning("Solar 数据不完整", category: Logger.app)
            return nil
        }

        // 计算正午时间（日出和日落的中间时间）
        let dayLength = sunset.timeIntervalSince(sunrise)
        let solarNoon = sunrise.addingTimeInterval(dayLength / 2)

        return SunTimes(
            sunrise: sunrise,
            sunset: sunset,
            solarNoon: solarNoon,
            civilDawn: nil,    // Solar 库不提供这些详细信息
            civilDusk: nil,
            nauticalDawn: nil,
            nauticalDusk: nil,
            astronomicalDawn: nil,
            astronomicalDusk: nil,
            dayLength: dayLength
        )
    }

    /// 判断当前时间是否为白天
    /// - Parameters:
    ///   - date: 日期时间
    ///   - location: 地理位置
    /// - Returns: 是否为白天
    func isDaytime(at date: Date, location: CLLocationCoordinate2D) -> Bool {
        guard let sunTimes = calculate(for: date, location: location) else {
            return false
        }

        return date >= sunTimes.sunrise && date <= sunTimes.sunset
    }

    /// 获取下一个日出时间
    func getNextSunrise(from date: Date, location: CLLocationCoordinate2D) -> Date? {
        // 检查今天的日出
        if let todaySunTimes = calculate(for: date, location: location),
           todaySunTimes.sunrise > date {
            return todaySunTimes.sunrise
        }

        // 返回明天的日出
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        return calculate(for: tomorrow, location: location)?.sunrise
    }

    /// 获取下一个日落时间
    func getNextSunset(from date: Date, location: CLLocationCoordinate2D) -> Date? {
        // 检查今天的日落
        if let todaySunTimes = calculate(for: date, location: location),
           todaySunTimes.sunset > date {
            return todaySunTimes.sunset
        }

        // 返回明天的日落
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        return calculate(for: tomorrow, location: location)?.sunset
    }

}
