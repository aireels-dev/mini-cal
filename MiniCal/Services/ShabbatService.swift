//
//  ShabbatService.swift
//  MiniCal
//
//  希伯来安息日（Shabbat）服务
//

import Foundation
import CoreLocation

class ShabbatService {
    static let shared = ShabbatService()

    private init() {}

    // MARK: - Shabbat Info Structure

    struct ShabbatInfo {
        let isShabbat: Bool         // 是否处于安息日时间
        let isShabbatDay: Bool      // 是否为安息日相关日（周五或周六）
        let shabbatStart: Date?     // 周五日落（安息日开始）
        let shabbatEnd: Date?       // 周六日落（安息日结束）
        let candleLighting: Date?   // 点蜡烛时间（日落前18分钟）
        let havdalah: Date?         // 分别仪式时间（日落后约42-72分钟，取决于传统）

        /// 距离下一个安息日的时间
        func timeUntilNextShabbat(from date: Date) -> TimeInterval? {
            guard let start = shabbatStart, start > date else {
                return nil
            }
            return start.timeIntervalSince(date)
        }

        /// 安息日状态描述
        var statusDescription: String {
            if isShabbat {
                return "安息日中"
            } else if isShabbatDay {
                return "安息日当天"
            } else {
                return "平日"
            }
        }
    }

    // MARK: - Public Methods

    /// 获取指定日期的安息日信息
    /// - Parameters:
    ///   - date: 日期时间
    ///   - location: 地理位置（用于计算日落时间）
    /// - Returns: 安息日信息
    func getShabbatInfo(for date: Date, location: CLLocationCoordinate2D) -> ShabbatInfo {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // 获取本周五和周六的日落时间
        let (fridaySunset, saturdaySunset) = getWeeklySunsets(for: date, location: location)

        // 周五日落到周六日落为安息日
        var isShabbat = false
        var isShabbatDay = false

        if let fridaySunset = fridaySunset, let saturdaySunset = saturdaySunset {
            // 判断是否在安息日时间段内
            isShabbat = date >= fridaySunset && date < saturdaySunset

            // 判断是否为安息日相关日（周五或周六）
            isShabbatDay = weekday == 6 || weekday == 7  // 6=周五, 7=周六
        }

        // 计算点蜡烛时间（周五日落前18分钟）
        let candleLighting = fridaySunset?.addingTimeInterval(-18 * 60)

        // 计算 Havdalah 时间（周六日落后42分钟，使用中等时间）
        let havdalah = saturdaySunset?.addingTimeInterval(42 * 60)

        return ShabbatInfo(
            isShabbat: isShabbat,
            isShabbatDay: isShabbatDay,
            shabbatStart: fridaySunset,
            shabbatEnd: saturdaySunset,
            candleLighting: candleLighting,
            havdalah: havdalah
        )
    }

    /// 获取下一个安息日的开始时间
    /// - Parameters:
    ///   - date: 当前日期
    ///   - location: 地理位置
    /// - Returns: 下一个安息日开始时间（周五日落）
    func getNextShabbatStart(from date: Date, location: CLLocationCoordinate2D) -> Date? {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)

        // 计算到下一个周五的天数
        var daysToAdd: Int
        if currentWeekday < 6 {  // 周日到周四
            daysToAdd = 6 - currentWeekday
        } else if currentWeekday == 6 {  // 周五
            // 检查是否已过日落
            if let todaySunset = SunTimeService.shared.calculate(for: date, location: location)?.sunset,
               date < todaySunset {
                return todaySunset
            } else {
                daysToAdd = 7  // 下周五
            }
        } else {  // 周六
            daysToAdd = 6
        }

        guard let nextFriday = calendar.date(byAdding: .day, value: daysToAdd, to: date) else {
            return nil
        }

        return SunTimeService.shared.calculate(for: nextFriday, location: location)?.sunset
    }

    /// 判断指定日期是否为犹太节日
    /// - Parameter date: 日期
    /// - Returns: 节日名称（如果是节日）
    func getJewishHoliday(for date: Date) -> String? {
        var calendar = Calendar(identifier: .hebrew)
        calendar.locale = Locale(identifier: "zh_CN")

        let components = calendar.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else {
            return nil
        }

        // 主要犹太节日
        switch (month, day) {
        case (1, 1), (1, 2):
            return "犹太新年"
        case (1, 10):
            return "赎罪日"
        case (1, 15):
            return "住棚节"
        case (7, 15):
            return "光明节"
        case (12, 14), (12, 15):
            return "普珥节"
        case (1, 15):
            return "逾越节"
        case (3, 6):
            return "五旬节"
        default:
            return nil
        }
    }

    // MARK: - Private Methods

    /// 获取指定日期所在周的周五和周六日落时间
    private func getWeeklySunsets(
        for date: Date,
        location: CLLocationCoordinate2D
    ) -> (friday: Date?, saturday: Date?) {
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)

        // 计算本周五的日期
        var daysToFriday = 6 - currentWeekday
        if daysToFriday < 0 {
            daysToFriday += 7
        }

        guard let friday = calendar.date(byAdding: .day, value: daysToFriday, to: date),
              let saturday = calendar.date(byAdding: .day, value: 1, to: friday) else {
            return (nil, nil)
        }

        let fridaySunset = SunTimeService.shared.calculate(for: friday, location: location)?.sunset
        let saturdaySunset = SunTimeService.shared.calculate(for: saturday, location: location)?.sunset

        return (fridaySunset, saturdaySunset)
    }

    /// 判断是否应该禁用某些功能（在安息日期间）
    /// 注意：这只是提示性功能，实际使用需遵循用户的宗教实践
    func shouldRestrictFunctionality(at date: Date, location: CLLocationCoordinate2D) -> Bool {
        let shabbatInfo = getShabbatInfo(for: date, location: location)
        return shabbatInfo.isShabbat
    }
}
