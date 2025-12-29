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

    func lastDayOfMonth(for date: Date) -> Date {
        let firstDay = firstDayOfMonth(for: date)
        let numberOfDays = numberOfDaysInMonth(for: date)
        return self.date(byAdding: .day, value: numberOfDays - 1, to: firstDay)!
    }

    func weekdayOfFirstDay(for date: Date) -> Int {
        let firstDay = firstDayOfMonth(for: date)
        return component(.weekday, from: firstDay)
    }

    /// 计算需要显示的上月日期数量（基于指定的每周起始日）
    /// - Parameters:
    ///   - date: 目标月份的任意日期
    ///   - weekStartDay: 每周起始日设置
    /// - Returns: 需要在月初填充的上月日期数量（0-6）
    func previousMonthDays(for date: Date, weekStartDay: WeekStartDay) -> Int {
        let firstDayWeekday = weekdayOfFirstDay(for: date)  // 1=周日, 2=周一, ..., 7=周六

        // 计算与起始日的偏移量
        let offset = (firstDayWeekday - weekStartDay.rawValue + 7) % 7
        return offset
    }
}
