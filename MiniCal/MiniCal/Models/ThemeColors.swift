//
//  ThemeColors.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct ThemeColors: Codable {
    let background: String
    let text: String
    let secondaryText: String
    let border: String
    let todayHighlight: String
    let weekendText: String
    let selectedDate: String

    // 兼容旧代码的accent属性
    var accent: String { todayHighlight }

    static let light = ThemeColors(
        background: "#FFFFFF",
        text: "#000000",
        secondaryText: "#666666",
        border: "#E0E0E0",
        todayHighlight: "#007AFF",
        weekendText: "#FF3B30",
        selectedDate: "#007AFF"
    )

    static let dark = ThemeColors(
        background: "#1C1C1E",
        text: "#FFFFFF",
        secondaryText: "#EBEBF5",
        border: "#38383A",
        todayHighlight: "#0A84FF",
        weekendText: "#FF453A",
        selectedDate: "#0A84FF"
    )

    func color(from hex: String) -> Color {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.hasPrefix("#") ? hex.index(after: hex.startIndex) : hex.startIndex

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }

    var backgroundColor: Color { color(from: background) }
    var textColor: Color { color(from: text) }
    var secondaryTextColor: Color { color(from: secondaryText) }
    var accentColor: Color { color(from: accent) }
    var borderColor: Color { color(from: border) }
    var todayHighlightColor: Color { color(from: todayHighlight) }
    var weekendTextColor: Color { color(from: weekendText) }
    var selectedDateColor: Color { color(from: selectedDate) }
}
