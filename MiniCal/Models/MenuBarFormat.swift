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
        case .dateOnly: return NSLocalizedString("menubar_format.date_only", comment: "")
        case .timeOnly: return NSLocalizedString("menubar_format.time_only", comment: "")
        case .dateTime: return NSLocalizedString("menubar_format.date_time", comment: "")
        case .custom: return NSLocalizedString("menubar_format.custom", comment: "")
        }
    }

    func format(date: Date, show24Hour: Bool, showWeekday: Bool, showSeconds: Bool, customFormat: String? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        switch self {
        case .dateOnly:
            formatter.dateFormat = showWeekday ? "M月d日 E" : "M月d日"
        case .timeOnly:
            if showSeconds {
                formatter.dateFormat = show24Hour ? "HH:mm:ss" : "h:mm:ss a"
            } else {
                formatter.dateFormat = show24Hour ? "HH:mm" : "h:mm a"
            }
        case .dateTime:
            var format = ""
            if showWeekday {
                if showSeconds {
                    format = show24Hour ? "M月d日 E HH:mm:ss" : "M月d日 E h:mm:ss a"
                } else {
                    format = show24Hour ? "M月d日 E HH:mm" : "M月d日 E h:mm a"
                }
            } else {
                if showSeconds {
                    format = show24Hour ? "M月d日 HH:mm:ss" : "M月d日 h:mm:ss a"
                } else {
                    format = show24Hour ? "M月d日 HH:mm" : "M月d日 h:mm a"
                }
            }
            formatter.dateFormat = format
        case .custom:
            formatter.dateFormat = customFormat ?? "M月d日 HH:mm"
        }

        return formatter.string(from: date)
    }
}
