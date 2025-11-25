import SwiftUI
import AppKit

// MARK: - EventColor Enum
enum EventColor: String, Codable, CaseIterable {
    case red, orange, blue, purple, green, gray, pink, teal, indigo, mint, cyan, yellow, brown

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .gray: return .gray
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        case .mint: return .mint
        case .cyan: return .cyan
        case .yellow: return .yellow
        case .brown: return .brown
        }
    }

    var nsColor: NSColor {
        switch self {
        case .red: return .systemRed
        case .orange: return .systemOrange
        case .blue: return .systemBlue
        case .purple: return .systemPurple
        case .green: return .systemGreen
        case .gray: return .systemGray
        case .pink: return .systemPink
        case .teal: return .systemTeal
        case .indigo: return .systemIndigo
        case .mint: return .systemMint
        case .cyan: return .systemCyan
        case .yellow: return .systemYellow
        case .brown: return .systemBrown
        }
    }

    var displayName: String {
        switch self {
        case .red: return "红色"
        case .orange: return "橙色"
        case .blue: return "蓝色"
        case .purple: return "紫色"
        case .green: return "绿色"
        case .gray: return "灰色"
        case .pink: return "粉色"
        case .teal: return "青色"
        case .indigo: return "靛蓝"
        case .mint: return "薄荷"
        case .cyan: return "青绿"
        case .yellow: return "黄色"
        case .brown: return "棕色"
        }
    }

    /// 从 Color 创建 EventColor（最佳匹配）
    init?(from color: Color) {
        // 尝试找到最匹配的颜色
        for eventColor in EventColor.allCases {
            if eventColor.swiftUIColor == color {
                self = eventColor
                return
            }
        }
        // 如果没有精确匹配，返回 nil
        return nil
    }
}
