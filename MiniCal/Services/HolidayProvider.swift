//
//  HolidayProvider.swift
//  MiniCal
//
//  Created on 2025/10/27.
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

class HolidayProvider {
    static let shared = HolidayProvider()

    private var holidaysCache: [String: [String: Holiday]] = [:]
    private let dateFormatter: DateFormatter

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        loadHolidayData()
    }

    func loadHolidayData() {
        // 加载中国节假日数据
        if let cnHolidays = loadHolidayFile(filename: "CN") {
            holidaysCache["CN"] = cnHolidays
        }
    }

    private func loadHolidayFile(filename: String) -> [String: Holiday]? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let holidayData = try? JSONDecoder().decode(HolidayData.self, from: data) else {
            return nil
        }

        var holidayDict: [String: Holiday] = [:]
        for holiday in holidayData.holidays {
            holidayDict[holiday.date] = holiday
        }
        return holidayDict
    }

    func getHolidays(for date: Date, region: String = "CN") -> [Holiday] {
        let dateString = dateFormatter.string(from: date)
        guard let regionHolidays = holidaysCache[region],
              let holiday = regionHolidays[dateString] else {
            return []
        }
        return [holiday]
    }

    func getMonthHolidays(year: Int, month: Int, region: String = "CN") -> [String: Holiday] {
        guard let regionHolidays = holidaysCache[region] else {
            return [:]
        }

        let monthString = String(format: "%04d-%02d", year, month)
        var monthHolidays: [String: Holiday] = [:]

        for (dateString, holiday) in regionHolidays {
            if dateString.hasPrefix(monthString) {
                monthHolidays[dateString] = holiday
            }
        }

        return monthHolidays
    }

    func isDataOutdated() -> Bool {
        // 检查最新节假日数据是否过期（示例：检查是否有当年数据）
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearString = String(currentYear)

        for regionHolidays in holidaysCache.values {
            for dateString in regionHolidays.keys {
                if dateString.hasPrefix(yearString) {
                    return false
                }
            }
        }

        return true
    }
}
