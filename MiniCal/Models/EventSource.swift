//
//  EventSource.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import SwiftUI

enum EventSource: String, Codable, CaseIterable {
    case builtin
    case eventKit
    case external
    case user

    /// 每种来源的默认颜色
    var defaultColor: Color {
        switch self {
        case .builtin:
            return .gray
        case .eventKit:
            return .blue
        case .external:
            return .green
        case .user:
            return .purple
        }
    }

    /// 来源显示名称
    var displayName: String {
        switch self {
        case .builtin:
            return "系统日历"
        case .eventKit:
            return "iCloud 日历"
        case .external:
            return "外部订阅"
        case .user:
            return "本地事件"
        }
    }
}
