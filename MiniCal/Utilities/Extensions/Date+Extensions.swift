//
//  Date+Extensions.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }

    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func adding(months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self)!
    }

    static func from(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }
}
