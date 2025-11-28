//
//  String+Localization.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation

extension String {
    /// 获取本地化字符串
    /// 使用示例: "menu_bar".localized()
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// 获取本地化字符串，带参数
    /// 使用示例: "event_count".localized(with: count)
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }

    /// 从指定的 table 获取本地化字符串
    func localized(from table: String) -> String {
        return NSLocalizedString(self, tableName: table, comment: "")
    }
}

/// 本地化辅助函数
func L(_ key: String) -> String {
    return key.localized
}

/// 历法专用本地化
func LC(_ key: String) -> String {
    return key.localized(from: "CalendarNames")
}

/// 节日专用本地化
func LF(_ key: String) -> String {
    return key.localized(from: "Festivals")
}
