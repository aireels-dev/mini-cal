//
//  EventType.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

enum EventType: String, Codable, CaseIterable {
    case publicHoliday
    case festival
    case meeting
    case birthday
    case custom

    var displayName: String {
        switch self {
        case .publicHoliday: return "公共假期"
        case .festival: return "节日"
        case .meeting: return "会议"
        case .birthday: return "生日"
        case .custom: return "自定义"
        }
    }

    var defaultColor: EventColor {
        switch self {
        case .publicHoliday: return .red
        case .festival: return .orange
        case .meeting: return .blue
        case .birthday: return .purple
        case .custom: return .green
        }
    }
}
