//
//  MenuBarFormat.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

enum MenuBarFormat: String, Codable, CaseIterable {
    case dateOnly
    case timeOnly
    case dateTime
    case custom

    var displayName: String {
        switch self {
        case .dateOnly: return "仅日期"
        case .timeOnly: return "仅时间"
        case .dateTime: return "日期+时间"
        case .custom: return "自定义"
        }
    }

    func format(date: Date, show24Hour: Bool, showWeekday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        switch self {
        case .dateOnly:
            formatter.dateFormat = showWeekday ? "M月d日 E" : "M月d日"
        case .timeOnly:
            formatter.dateFormat = show24Hour ? "HH:mm" : "h:mm a"
        case .dateTime:
            if showWeekday {
                formatter.dateFormat = show24Hour ? "M月d日 E HH:mm" : "M月d日 E h:mm a"
            } else {
                formatter.dateFormat = show24Hour ? "M月d日 HH:mm" : "M月d日 h:mm a"
            }
        case .custom:
            // For now, default to dateTime
            formatter.dateFormat = show24Hour ? "M月d日 HH:mm" : "M月d日 h:mm a"
        }

        return formatter.string(from: date)
    }
}
