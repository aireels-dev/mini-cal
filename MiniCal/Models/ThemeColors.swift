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
        background: "#FAFAFA",        // 柔和白色背景（非纯白）
        text: "#1C1C1E",              // 深灰文字（非纯黑）
        secondaryText: "#8E8E93",     // Apple 标准次要文字色
        border: "#E5E5EA",            // 柔和边框色
        todayHighlight: "#007AFF",    // Apple 蓝
        weekendText: "#FF6B6B",       // 柔和红色
        selectedDate: "#007AFF"
    )

    static let dark = ThemeColors(
        background: "#1C1C1E",        // Apple 标准深色背景
        text: "#F5F5F7",              // 柔和白色（非纯白）
        secondaryText: "#98989D",     // Apple 标准次要文字色
        border: "#2C2C2E",            // 深灰边框
        todayHighlight: "#0A84FF",    // Apple 蓝（深色模式）
        weekendText: "#FF6B6B",       // 柔和红色（统一色值）
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
