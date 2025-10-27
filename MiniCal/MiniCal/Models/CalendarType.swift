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
        switch self {
        case .gregorian: return "公历"
        case .chinese: return "农历"
        case .islamic: return "伊斯兰历"
        case .hebrew: return "希伯来历"
        case .persian: return "波斯历"
        case .japanese: return "和历"
        case .buddhist: return "佛历"
        }
    }
}
