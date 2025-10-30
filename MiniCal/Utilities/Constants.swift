//
//  Constants.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct Constants {
    // UserDefaults Keys
    struct UserDefaultsKeys {
        static let settings = "MiniCal.Settings"
    }

    // Timing
    struct Timing {
        static let hoverDelay: TimeInterval = 0.5 // 0.5 seconds
        static let debounceDelay: TimeInterval = 0.1 // 100ms
    }

    // Performance
    struct Performance {
        static let cacheSize = 12 // Cache up to 12 months
    }

    // Calendar
    struct Calendar {
        static let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
        static let chineseMonthNames = ["正月", "二月", "三月", "四月", "五月", "六月",
                                       "七月", "八月", "九月", "十月", "冬月", "腊月"]
    }
}
