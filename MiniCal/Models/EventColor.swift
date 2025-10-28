//
//  EventColor.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

enum EventColor: String, Codable {
    case red, orange, blue, purple, green, gray

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .gray: return .gray
        }
    }
}
