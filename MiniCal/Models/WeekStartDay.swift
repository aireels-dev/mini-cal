//
//  WeekStartDay.swift
//  MiniCal
//
//  Created on 2025/12/26.
//

import Foundation

/// 每周起始日设置
enum WeekStartDay: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1     // 周日（对应 Calendar.Weekday.sunday）
    case monday = 2     // 周一（对应 Calendar.Weekday.monday）

    var id: Int { rawValue }

    /// 本地化显示名称
    var displayName: String {
        switch self {
        case .sunday:
            return NSLocalizedString("weekday.sunday", comment: "周日")
        case .monday:
            return NSLocalizedString("weekday.monday", comment: "周一")
        }
    }

    /// 简短描述
    var shortDescription: String {
        switch self {
        case .sunday:
            return NSLocalizedString("settings.week_start.sunday_desc", comment: "从周日开始（美国、日本等）")
        case .monday:
            return NSLocalizedString("settings.week_start.monday_desc", comment: "从周一开始（中国、欧洲等）")
        }
    }

    /// 默认值：根据用户区域自动检测
    static var `default`: WeekStartDay {
        let calendar = Calendar.current

        // 使用系统 Calendar 的 firstWeekday 属性
        // firstWeekday: 1 = 周日, 2 = 周一
        let systemFirstWeekday = calendar.firstWeekday

        if systemFirstWeekday == 2 {
            return .monday
        } else {
            return .sunday
        }
    }
}
