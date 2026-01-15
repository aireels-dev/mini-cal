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
        // 注意：这些键值使用 "MiniCal" 前缀，不应修改以避免用户数据丢失
        // 仅用于文档说明，实际键值在各 Service 中定义
        static let settingsBase = "MiniCal"
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
