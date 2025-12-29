//
//  HolidayProvider.swift
//  MiniCal
//
//  [已废弃] 本地节假日数据提供者 - 现在通过外部订阅获取节假日数据
//  保留此文件以维持向后兼容性，所有方法返回空数据
//

import Foundation

struct Holiday: Codable {
    let date: String
    let name: String
    let type: String
    let isPublicHoliday: Bool

    var eventType: EventType {
        switch type {
        case "holiday":
            return .publicHoliday
        case "festival":
            return .festival
        default:
            return .publicHoliday
        }
    }
}

struct HolidayData: Codable {
    let country: String
    let name: String
    let holidays: [Holiday]
}

/// [已废弃] 本地节假日提供者
/// 节假日数据现在通过外部日历订阅获取（iCal格式）
class HolidayProvider {
    static let shared = HolidayProvider()

    private let dateFormatter: DateFormatter

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        Logger.warning("⚠️ HolidayProvider is deprecated. Holiday data should be fetched via external calendar subscriptions.", category: Logger.calendar)
    }

    /// [已废弃] 返回空数组，节假日应通过外部订阅获取
    func getHolidays(for date: Date, region: String = "CN") -> [Holiday] {
        return []
    }

    /// [已废弃] 返回空字典，节假日应通过外部订阅获取
    func getMonthHolidays(year: Int, month: Int, region: String = "CN") -> [String: Holiday] {
        return [:]
    }

    /// [已废弃] 总是返回 true，提示用户添加外部订阅
    func isDataOutdated() -> Bool {
        return true
    }
}
