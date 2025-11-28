//
//  CalendarType.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

enum CalendarType: String, Codable, CaseIterable {
    case gregorian
    case chinese
    case islamic
    case hebrew
    case persian
    case japanese
    case buddhist

    var identifier: Calendar.Identifier? {
        switch self {
        case .gregorian: return .gregorian
        case .chinese: return .chinese
        case .islamic: return .islamic
        case .hebrew: return .hebrew
        case .persian: return .persian
        case .japanese: return .japanese
        case .buddhist: return nil // Custom implementation
        }
    }

    var displayName: String {
        // 使用本地化管理器获取名称
        return CalendarLocalizer.shared.calendarTypeName(self)
    }

    /// 获取非本地化的名称（用于调试）
    var rawDisplayName: String {
        switch self {
        case .gregorian: return "Gregorian"
        case .chinese: return "Chinese Lunar"
        case .islamic: return "Islamic"
        case .hebrew: return "Hebrew"
        case .persian: return "Persian"
        case .japanese: return "Japanese"
        case .buddhist: return "Buddhist"
        }
    }
}
