//
//  SecondaryDateInfo.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct SecondaryDateInfo: Codable, Equatable {
    let calendarType: CalendarType
    let displayText: String
    let year: Int?
    let month: Int?
    let day: Int?
    let festival: String?                // 特定历法的节日（农历节日、伊斯兰节日等）
    let festivalID: String?              // 节日唯一标识符（用于程序判断，非显示）

    // 扩展字段：公历节日（全局显示，所有历法都会显示）
    let solarFestival: String?
    let solarFestivalID: String?         // 公历节日ID

    // 扩展字段：伊斯兰历礼拜时间信息（可选）
    let nextPrayerInfo: PrayerInfo?

    // 扩展字段：希伯来历安息日信息（可选）
    let shabbatDisplayInfo: ShabbatDisplayInfo?
}

// MARK: - Prayer Info

/// 下一个礼拜时间信息
struct PrayerInfo: Codable, Equatable {
    let nextPrayerName: String   // 下一个礼拜名称
    let nextPrayerTime: Date     // 下一个礼拜时间
}

// MARK: - Shabbat Display Info

/// 安息日显示信息（简化版，用于日历单元格）
struct ShabbatDisplayInfo: Codable, Equatable {
    let isShabbat: Bool          // 是否处于安息日时间
    let shabbatStart: Date?      // 安息日开始时间（周五日落）
    let shabbatEnd: Date?        // 安息日结束时间（周六日落）
}
