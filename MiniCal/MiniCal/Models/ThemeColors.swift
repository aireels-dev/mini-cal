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
    let accent: String
    let border: String
    let todayHighlight: String
    let weekendText: String

    static let light = ThemeColors(
        background: "#FFFFFF",
        text: "#000000",
        secondaryText: "#8E8E93",
        accent: "#007AFF",
        border: "#E5E5EA",
        todayHighlight: "#FFCC00",
        weekendText: "#FF3B30"
    )

    static let dark = ThemeColors(
        background: "#1C1C1E",
        text: "#FFFFFF",
        secondaryText: "#8E8E93",
        accent: "#0A84FF",
        border: "#38383A",
        todayHighlight: "#FFD60A",
        weekendText: "#FF453A"
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
}
