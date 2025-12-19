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
        // 使用界面语言的locale进行日期格式化
        let localeIdentifier = LocalizationManager.shared.context.effectiveInterfaceLocale.rawValue
        formatter.locale = Locale(identifier: localeIdentifier)

        switch self {
        case .dateOnly:
            // 使用locale自动生成日期格式，使用月份缩写（中文显示"11月18日"，英文显示"Nov 18"）
            let template = showWeekday ? "MMMdE" : "MMMd"
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: formatter.locale)
        case .timeOnly:
            // 时间格式
            if showSeconds {
                formatter.dateFormat = show24Hour ? "HH:mm:ss" : "h:mm:ss a"
            } else {
                formatter.dateFormat = show24Hour ? "HH:mm" : "h:mm a"
            }
        case .dateTime:
            // 使用locale自动生成日期时间格式，使用月份缩写（中文显示"11月18日 14:30"，英文显示"Nov 18, 2:30 PM"）
            var template = ""
            if showWeekday {
                if showSeconds {
                    template = show24Hour ? "MMMdEHms" : "MMMdehms"
                } else {
                    template = show24Hour ? "MMMdEHm" : "MMMdehm"
                }
            } else {
                if showSeconds {
                    template = show24Hour ? "MMMdHms" : "MMMdhms"
                } else {
                    template = show24Hour ? "MMMdHm" : "MMMdhm"
                }
            }
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: formatter.locale)
        case .custom:
            formatter.dateFormat = customFormat ?? DateFormatter.dateFormat(fromTemplate: "MMMdHm", options: 0, locale: formatter.locale)
        }

        return formatter.string(from: date)
    }
}
