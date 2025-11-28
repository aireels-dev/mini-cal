//
//  PrayerTimeService.swift
//  MiniCal
//
//  伊斯兰礼拜时间计算服务
//  依赖：Adhan 库 (https://github.com/batoulapps/adhan-swift)
//

import Foundation
import CoreLocation
import Adhan

class PrayerTimeService {
    static let shared = PrayerTimeService()

    private let festivalLocalizer = FestivalLocalizer.shared

    private init() {}

    // MARK: - Prayer Times Structure

    struct PrayerTimes {
        let fajr: Date      // 晨礼（Fajr）- 黎明
        let sunrise: Date   // 日出（Sunrise）- 不是礼拜时间，但重要参考
        let dhuhr: Date     // 晌礼（Dhuhr）- 正午
        let asr: Date       // 晡礼（Asr）- 下午
        let maghrib: Date   // 昏礼（Maghrib）- 日落
        let isha: Date      // 宵礼（Isha）- 夜晚

        /// 所有礼拜时间列表（使用本地化名称）
        var allPrayers: [(name: String, time: Date)] {
            let localizer = FestivalLocalizer.shared
            return [
                (localizer.prayerTimeName("Fajr"), fajr),
                (localizer.prayerTimeName("Dhuhr"), dhuhr),
                (localizer.prayerTimeName("Asr"), asr),
                (localizer.prayerTimeName("Maghrib"), maghrib),
                (localizer.prayerTimeName("Isha"), isha)
            ]
        }

        /// 获取下一个礼拜时间
        func getNextPrayer(from date: Date) -> (name: String, time: Date)? {
            return allPrayers.first(where: { $0.time > date })
        }

        /// 获取当前礼拜时间段
        func getCurrentPrayer(at date: Date) -> (name: String, time: Date)? {
            let prayers = allPrayers
            for i in 0..<prayers.count {
                let current = prayers[i]
                let next = i < prayers.count - 1 ? prayers[i + 1] : nil

                if date >= current.time && (next == nil || date < next!.time) {
                    return current
                }
            }
            return nil
        }
    }

    // MARK: - Calculation Methods

    enum CalculationMethod: String, CaseIterable {
        case muslimWorldLeague
        case egyptian
        case karachi
        case ummAlQura
        case dubai
        case moonsightingCommittee
        case northAmerica
        case kuwait
        case qatar
        case singapore

        var localizedName: String {
            let key = "prayer_method_\(self.rawValue)"
            return LocalizationManager.shared.localized(key, table: "Festivals")
        }
    }

    // MARK: - Public Methods

    /// 计算指定日期和位置的礼拜时间
    /// - Parameters:
    ///   - date: 日期
    ///   - location: 地理位置坐标
    ///   - method: 计算方法（默认：穆斯林世界联盟）
    /// - Returns: 礼拜时间信息，如果计算失败返回 nil
    func calculatePrayerTimes(
        for date: Date,
        location: CLLocationCoordinate2D,
        method: CalculationMethod = .muslimWorldLeague
    ) -> PrayerTimes? {
        // 使用 Adhan 库进行精确计算
        let coordinates = Coordinates(
            latitude: location.latitude,
            longitude: location.longitude
        )

        // 选择计算参数 - 使用 Adhan 库的 CalculationMethod
        let params: CalculationParameters
        switch method {
        case .muslimWorldLeague:
            params = Adhan.CalculationMethod.muslimWorldLeague.params
        case .egyptian:
            params = Adhan.CalculationMethod.egyptian.params
        case .karachi:
            params = Adhan.CalculationMethod.karachi.params
        case .ummAlQura:
            params = Adhan.CalculationMethod.ummAlQura.params
        case .dubai:
            params = Adhan.CalculationMethod.dubai.params
        case .moonsightingCommittee:
            params = Adhan.CalculationMethod.moonsightingCommittee.params
        case .northAmerica:
            params = Adhan.CalculationMethod.northAmerica.params
        case .kuwait:
            params = Adhan.CalculationMethod.kuwait.params
        case .qatar:
            params = Adhan.CalculationMethod.qatar.params
        case .singapore:
            params = Adhan.CalculationMethod.singapore.params
        }

        // 转换 Date 为 DateComponents
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        guard let adhanPrayerTimes = Adhan.PrayerTimes(
            coordinates: coordinates,
            date: dateComponents,
            calculationParameters: params
        ) else {
            Logger.warning("Adhan 计算失败", category: Logger.app)
            return nil
        }

        return PrayerTimes(
            fajr: adhanPrayerTimes.fajr,
            sunrise: adhanPrayerTimes.sunrise,
            dhuhr: adhanPrayerTimes.dhuhr,
            asr: adhanPrayerTimes.asr,
            maghrib: adhanPrayerTimes.maghrib,
            isha: adhanPrayerTimes.isha
        )
    }

    /// 判断当前是否在礼拜时间窗口内
    /// - Parameters:
    ///   - date: 当前时间
    ///   - location: 地理位置
    ///   - windowMinutes: 礼拜时间前后的窗口（分钟）
    /// - Returns: 是否在礼拜时间窗口内
    func isWithinPrayerWindow(
        at date: Date,
        location: CLLocationCoordinate2D,
        windowMinutes: Int = 15
    ) -> Bool {
        guard let prayerTimes = calculatePrayerTimes(for: date, location: location) else {
            return false
        }

        let windowInterval = TimeInterval(windowMinutes * 60)

        for (_, prayerTime) in prayerTimes.allPrayers {
            let lowerBound = prayerTime.addingTimeInterval(-windowInterval)
            let upperBound = prayerTime.addingTimeInterval(windowInterval)

            if date >= lowerBound && date <= upperBound {
                return true
            }
        }

        return false
    }

}
