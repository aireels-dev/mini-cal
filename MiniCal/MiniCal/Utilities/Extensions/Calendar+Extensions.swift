//
//  Calendar+Extensions.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

extension Calendar {
    func numberOfDaysInMonth(for date: Date) -> Int {
        return range(of: .day, in: .month, for: date)?.count ?? 30
    }

    func firstDayOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }

    func weekdayOfFirstDay(for date: Date) -> Int {
        let firstDay = firstDayOfMonth(for: date)
        return component(.weekday, from: firstDay)
    }
}
