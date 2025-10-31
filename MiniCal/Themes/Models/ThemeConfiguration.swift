//
//  ThemeConfiguration.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI
import Foundation

// MARK: - Theme Configuration

/// 主题的颜色定义和样式配置
struct ThemeConfiguration: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let category: ThemeCategory
    let isBuiltIn: Bool

    // 主要颜色配置
    let primary: ColorSet
    let secondary: ColorSet
    let accent: ColorSet
    let background: ColorSet
    let surface: ColorSet

    // 文本颜色
    let text: TextColorSet

    // 特殊用途颜色
    let calendar: CalendarColorSet
    let status: StatusColorSet

    // 元数据
    let author: String?
    let version: String
    let description: String?
    let previewColors: [String] // 用于设置界面预览

    // 默认实现
    static let defaultLight = ThemeConfiguration(
        id: "classic_blue",
        name: "Classic Blue",
        displayName: "经典蓝",
        category: .light,
        isBuiltIn: true,
        primary: ColorSet(main: "#4285F4", light: "#5A95F5", dark: "#357AE8"),
        secondary: ColorSet(main: "#34A853", light: "#4CB565", dark: "#2D8F47"),
        accent: ColorSet(main: "#FBBC04", light: "#FCC934", dark: "#F9AB00"),
        background: ColorSet(main: "#FFFFFF", light: "#FAFAFA", dark: "#F5F5F5"),
        surface: ColorSet(main: "#F8F9FA", light: "#F1F3F4", dark: "#E8EAED"),
        text: TextColorSet(
            primary: "#202124",
            secondary: "#5F6368",
            disabled: "#9AA0A6",
            inverse: "#FFFFFF"
        ),
        calendar: CalendarColorSet(
            todayBackground: "#E8F0FE",
            todayText: "#1967D2",
            selectedBackground: "#4285F4",
            selectedText: "#FFFFFF",
            weekendText: "#EA4335",
            eventIndicator: "#FBBC04"
        ),
        status: StatusColorSet(
            success: "#34A853",
            warning: "#FBBC04",
            error: "#EA4335",
            info: "#4285F4"
        ),
        author: "MiniCal Team",
        version: "1.0",
        description: "Chrome风格的经典蓝色主题",
        previewColors: ["#4285F4", "#FFFFFF", "#202124", "#34A853"]
    )

    static let defaultDark = ThemeConfiguration(
        id: "midnight_blue",
        name: "Midnight Blue",
        displayName: "午夜蓝",
        category: .dark,
        isBuiltIn: true,
        primary: ColorSet(main: "#1A73E8", light: "#2B7DE9", dark: "#1557B0"),
        secondary: ColorSet(main: "#1E8E3E", light: "#2F9E4E", dark: "#0D652D"),
        accent: ColorSet(main: "#F9AB00", light: "#FCC934", dark: "#E37400"),
        background: ColorSet(main: "#202124", light: "#2D2E30", dark: "#171717"),
        surface: ColorSet(main: "#2D2E30", light: "#3C4043", dark: "#1E1E1E"),
        text: TextColorSet(
            primary: "#E8EAED",
            secondary: "#9AA0A6",
            disabled: "#5F6368",
            inverse: "#202124"
        ),
        calendar: CalendarColorSet(
            todayBackground: "#1E3A8A",
            todayText: "#93C5FD",
            selectedBackground: "#1A73E8",
            selectedText: "#FFFFFF",
            weekendText: "#F87171",
            eventIndicator: "#FBBF24"
        ),
        status: StatusColorSet(
            success: "#1E8E3E",
            warning: "#F9AB00",
            error: "#F87171",
            info: "#1A73E8"
        ),
        author: "MiniCal Team",
        version: "1.0",
        description: "深邃的午夜蓝色主题，适合夜间使用",
        previewColors: ["#1A73E8", "#202124", "#E8EAED", "#1E8E3E"]
    )
}

// MARK: - Supporting Types

/// 颜色集合
struct ColorSet: Codable, Equatable {
    let main: String      // HEX格式
    let light: String?    // 浅色变体
    let dark: String?     // 深色变体
    let alpha: Double?    // 透明度 (0.0-1.0)

    init(main: String, light: String? = nil, dark: String? = nil, alpha: Double? = nil) {
        self.main = main
        self.light = light
        self.dark = dark
        self.alpha = alpha
    }
}

/// 文本颜色集合
struct TextColorSet: Codable, Equatable {
    let primary: String
    let secondary: String
    let disabled: String
    let inverse: String

    init(primary: String, secondary: String, disabled: String, inverse: String) {
        self.primary = primary
        self.secondary = secondary
        self.disabled = disabled
        self.inverse = inverse
    }
}

/// 日历专用颜色集合
struct CalendarColorSet: Codable, Equatable {
    let todayBackground: String
    let todayText: String
    let selectedBackground: String
    let selectedText: String
    let weekendText: String
    let eventIndicator: String

    init(todayBackground: String, todayText: String, selectedBackground: String,
         selectedText: String, weekendText: String, eventIndicator: String) {
        self.todayBackground = todayBackground
        self.todayText = todayText
        self.selectedBackground = selectedBackground
        self.selectedText = selectedText
        self.weekendText = weekendText
        self.eventIndicator = eventIndicator
    }
}

/// 状态指示颜色集合
struct StatusColorSet: Codable, Equatable {
    let success: String
    let warning: String
    let error: String
    let info: String

    init(success: String, warning: String, error: String, info: String) {
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
    }
}

// MARK: - Validation

extension ThemeConfiguration {
    /// 验证主题配置的有效性
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // 检查必需字段
        if id.isEmpty {
            errors.append(ValidationError(field: "id", message: "主题ID不能为空"))
        }

        if name.isEmpty {
            errors.append(ValidationError(field: "name", message: "主题名称不能为空"))
        }

        // 检查颜色格式
        let colorValidator = ColorValidator()
        errors.append(contentsOf: colorValidator.validate(primary.main, field: "primary.main"))
        errors.append(contentsOf: colorValidator.validate(background.main, field: "background.main"))

        // 检查颜色对比度
        let contrastValidator = ContrastValidator()
        if !contrastValidator.isValidContrast(primary.main, text.primary) {
            errors.append(ValidationError(
                field: "contrast",
                message: "主要颜色与文本颜色对比度不足"
            ))
        }

        return errors
    }
}

// MARK: - Validation Types

/// 验证错误
struct ValidationError: Error, LocalizedError {
    let field: String
    let message: String

    var errorDescription: String? {
        return "\(field): \(message)"
    }
}

/// 颜色验证器
struct ColorValidator {
    func validate(_ hex: String, field: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        if !isValidHex(hex) {
            errors.append(ValidationError(
                field: field,
                message: "无效的HEX颜色格式: \(hex)"
            ))
        }

        return errors
    }

    private func isValidHex(_ hex: String) -> Bool {
        let regex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: hex)
    }
}

/// 对比度验证器
struct ContrastValidator {
    func isValidContrast(_ foreground: String, _ background: String) -> Bool {
        // 简化的对比度检查 - 实际实现需要更复杂的颜色空间转换
        let foregroundLuminance = calculateLuminance(foreground)
        let backgroundLuminance = calculateLuminance(background)

        let contrast = (max(foregroundLuminance, backgroundLuminance) + 0.05) /
                       (min(foregroundLuminance, backgroundLuminance) + 0.05)

        return contrast >= 4.5 // WCAG AA 标准
    }

    private func calculateLuminance(_ hex: String) -> Double {
        // 简化的亮度计算 - 实际实现需要sRGB转换
        guard hex.hasPrefix("#") else { return 0 }

        let rgb = hex.dropFirst()
        let length = rgb.count

        var r: Double = 0, g: Double = 0, b: Double = 0

        if length == 6 {
            let start = rgb.startIndex
            let rStr = String(rgb[start..<rgb.index(start, offsetBy: 2)])
            let gStr = String(rgb[rgb.index(start, offsetBy: 2)..<rgb.index(start, offsetBy: 4)])
            let bStr = String(rgb[rgb.index(start, offsetBy: 4)..<rgb.index(start, offsetBy: 6)])
            r = Double(Int(rStr, radix: 16) ?? 0) / 255.0
            g = Double(Int(gStr, radix: 16) ?? 0) / 255.0
            b = Double(Int(bStr, radix: 16) ?? 0) / 255.0
        } else if length == 3 {
            let start = rgb.startIndex
            let rStr = String(rgb[start]) + String(rgb[start])
            let gStr = String(rgb[rgb.index(start, offsetBy: 1)]) + String(rgb[rgb.index(start, offsetBy: 1)])
            let bStr = String(rgb[rgb.index(start, offsetBy: 2)]) + String(rgb[rgb.index(start, offsetBy: 2)])
            r = Double(Int(rStr, radix: 16) ?? 0) / 255.0
            g = Double(Int(gStr, radix: 16) ?? 0) / 255.0
            b = Double(Int(bStr, radix: 16) ?? 0) / 255.0
        }

        // 简化的相对亮度计算
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}

// MARK: - Built-in Themes

struct BuiltInThemes {

    // MARK: - Light Themes

    static let classicBlue = ThemeConfiguration(
        id: "classic_blue_new",
        name: "Classic Blue",
        displayName: "经典蓝",
        category: .light,
        isBuiltIn: true,
        primary: ColorSet(main: "#4285F4", light: "#5A95F5", dark: "#357AE8"),
        secondary: ColorSet(main: "#34A853", light: "#4CB565", dark: "#2D8F47"),
        accent: ColorSet(main: "#FBBC04", light: "#FCC934", dark: "#F9AB00"),
        background: ColorSet(main: "#FFFFFF", light: "#FFFFFF", dark: "#FFFFFF"),
        surface: ColorSet(main: "#F8F9FA", light: "#FFFFFF", dark: "#F1F3F4"),
        text: TextColorSet(primary: "#000000", secondary: "#5F6368", disabled: "#C7C7CC", inverse: "#FFFFFF"),
        calendar: CalendarColorSet(
            todayBackground: "#4285F4",
            todayText: "#FFFFFF",
            selectedBackground: "#007AFF",
            selectedText: "#FFFFFF",
            weekendText: "#EA4335",
            eventIndicator: "#FBBC04"
        ),
        status: StatusColorSet(
            success: "#34A853",
            warning: "#FBBC04",
            error: "#EA4335",
            info: "#4285F4"
        ),
        author: "MiniCal",
        version: "1.0.0",
        description: "经典蓝色主题，专业稳重的选择",
        previewColors: ["#4285F4", "#34A853", "#FBBC04", "#FFFFFF"]
    )

    static let freshGreen = ThemeConfiguration(
        id: "fresh_green",
        name: "Fresh Green",
        displayName: "清新绿",
        category: .light,
        isBuiltIn: true,
        primary: ColorSet(main: "#34C759", light: "#4CD964", dark: "#30B157"),
        secondary: ColorSet(main: "#30D158", light: "#32D760", dark: "#2FC855"),
        accent: ColorSet(main: "#007AFF", light: "#007AFF", dark: "#0051D5"),
        background: ColorSet(main: "#FFFFFF", light: "#FFFFFF", dark: "#FFFFFF"),
        surface: ColorSet(main: "#F0FFF4", light: "#F5FFF7", dark: "#E8F5E8"),
        text: TextColorSet(primary: "#000000", secondary: "#5F6368", disabled: "#C7C7CC", inverse: "#FFFFFF"),
        calendar: CalendarColorSet(
            todayBackground: "#34C759",
            todayText: "#FFFFFF",
            selectedBackground: "#30D158",
            selectedText: "#FFFFFF",
            weekendText: "#FF3B30",
            eventIndicator: "#FF9500"
        ),
        status: StatusColorSet(
            success: "#34C759",
            warning: "#FF9500",
            error: "#FF3B30",
            info: "#007AFF"
        ),
        author: "MiniCal",
        version: "1.0.0",
        description: "清新绿色主题，自然护眼",
        previewColors: ["#34C759", "#30D158", "#007AFF", "#FFFFFF"]
    )

    static let sunsetOrange = ThemeConfiguration(
        id: "sunset_orange",
        name: "Sunset Orange",
        displayName: "夕阳橙",
        category: .light,
        isBuiltIn: true,
        primary: ColorSet(main: "#FF9500", light: "#FFA500", dark: "#FF8C00"),
        secondary: ColorSet(main: "#FF6B35", light: "#FF8A65", dark: "#FF5722"),
        accent: ColorSet(main: "#007AFF", light: "#007AFF", dark: "#0051D5"),
        background: ColorSet(main: "#FFFFFF", light: "#FFFFFF", dark: "#FFFFFF"),
        surface: ColorSet(main: "#FFF8F0", light: "#FFFAF5", dark: "#FFF3E0"),
        text: TextColorSet(primary: "#000000", secondary: "#5F6368", disabled: "#C7C7CC", inverse: "#FFFFFF"),
        calendar: CalendarColorSet(
            todayBackground: "#FF9500",
            todayText: "#FFFFFF",
            selectedBackground: "#FF8C00",
            selectedText: "#FFFFFF",
            weekendText: "#FF3B30",
            eventIndicator: "#34C759"
        ),
        status: StatusColorSet(
            success: "#34C759",
            warning: "#FF9500",
            error: "#FF3B30",
            info: "#007AFF"
        ),
        author: "MiniCal",
        version: "1.0.0",
        description: "温暖橙色主题，充满活力",
        previewColors: ["#FF9500", "#FF6B35", "#007AFF", "#FFFFFF"]
    )

    // MARK: - Dark Themes

    static let midnightBlue = ThemeConfiguration(
        id: "midnight_blue",
        name: "Midnight Blue",
        displayName: "午夜蓝",
        category: .dark,
        isBuiltIn: true,
        primary: ColorSet(main: "#0A84FF", light: "#409CFF", dark: "#0969DA"),
        secondary: ColorSet(main: "#5E5CE6", light: "#7B7FF0", dark: "#5048D5"),
        accent: ColorSet(main: "#FF9F0A", light: "#FFB347", dark: "#FF8C00"),
        background: ColorSet(main: "#000000", light: "#000000", dark: "#000000"),
        surface: ColorSet(main: "#1C1C1E", light: "#2C2C2E", dark: "#0C0C0E"),
        text: TextColorSet(primary: "#FFFFFF", secondary: "#98989D", disabled: "#636366", inverse: "#000000"),
        calendar: CalendarColorSet(
            todayBackground: "#0A84FF",
            todayText: "#FFFFFF",
            selectedBackground: "#0969DA",
            selectedText: "#FFFFFF",
            weekendText: "#FF453A",
            eventIndicator: "#FF9F0A"
        ),
        status: StatusColorSet(
            success: "#30D158",
            warning: "#FF9F0A",
            error: "#FF453A",
            info: "#0A84FF"
        ),
        author: "MiniCal",
        version: "1.0.0",
        description: "深邃蓝色主题，静谧优雅",
        previewColors: ["#0A84FF", "#5E5CE6", "#FF9F0A", "#000000"]
    )

    static let forestGreen = ThemeConfiguration(
        id: "forest_green",
        name: "Forest Green",
        displayName: "森林绿",
        category: .dark,
        isBuiltIn: true,
        primary: ColorSet(main: "#32D74B", light: "#40E057", dark: "#28C743"),
        secondary: ColorSet(main: "#30B97B", light: "#40C98B", dark: "#25A971"),
        accent: ColorSet(main: "#FF9F0A", light: "#FFB347", dark: "#FF8C00"),
        background: ColorSet(main: "#000000", light: "#000000", dark: "#000000"),
        surface: ColorSet(main: "#0D2818", light: "#1A3828", dark: "#081810"),
        text: TextColorSet(primary: "#FFFFFF", secondary: "#98989D", disabled: "#636366", inverse: "#000000"),
        calendar: CalendarColorSet(
            todayBackground: "#32D74B",
            todayText: "#000000",
            selectedBackground: "#28C743",
            selectedText: "#000000",
            weekendText: "#FF453A",
            eventIndicator: "#FF9F0A"
        ),
        status: StatusColorSet(
            success: "#30D158",
            warning: "#FF9F0A",
            error: "#FF453A",
            info: "#0A84FF"
        ),
        author: "MiniCal",
        version: "1.0.0",
        description: "深林绿色主题，自然平和",
        previewColors: ["#32D74B", "#30B97B", "#FF9F0A", "#000000"]
    )

    static let graphiteGray = ThemeConfiguration(
        id: "graphite_gray",
        name: "Graphite Gray",
        displayName: "石墨灰",
        category: .dark,
        isBuiltIn: true,
        primary: ColorSet(main: "#8E8E93", light: "#A1A1A6", dark: "#7D7D82"),
        secondary: ColorSet(main: "#AEAEB2", light: "#C1C1C6", dark: "#9B9BA0"),
        accent: ColorSet(main: "#007AFF", light: "#409CFF", dark: "#0051D5"),
        background: ColorSet(main: "#000000", light: "#000000", dark: "#000000"),
        surface: ColorSet(main: "#1C1C1E", light: "#2C2C2E", dark: "#0C0C0E"),
        text: TextColorSet(primary: "#FFFFFF", secondary: "#98989D", disabled: "#636366", inverse: "#000000"),
        calendar: CalendarColorSet(
            todayBackground: "#8E8E93",
            todayText: "#000000",
            selectedBackground: "#7D7D82",
            selectedText: "#000000",
            weekendText: "#FF453A",
            eventIndicator: "#FF9F0A"
        ),
        status: StatusColorSet(
            success: "#30D158",
            warning: "#FF9F0A",
            error: "#FF453A",
            info: "#0A84FF"
        ),
        author: "MiniCal",
        version: "1.0.0",
        description: "中性灰色主题，低调优雅",
        previewColors: ["#8E8E93", "#AEAEB2", "#007AFF", "#000000"]
    )

    // MARK: - Collections

    static var lightThemes: [ThemeConfiguration] {
        [classicBlue, freshGreen, sunsetOrange]
    }

    static var darkThemes: [ThemeConfiguration] {
        [midnightBlue, forestGreen, graphiteGray]
    }

    static var allThemes: [ThemeConfiguration] {
        lightThemes + darkThemes
    }

    // MARK: - Default Themes

    static var defaultLight: ThemeConfiguration {
        classicBlue
    }

    static var defaultDark: ThemeConfiguration {
        midnightBlue
    }
}