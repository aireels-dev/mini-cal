//
//  ThemeColors.swift
//  MiniCal
//
//  Created by MiniCal on 2025/11/13.
//  完整的主题颜色定义，包含34个颜色属性
//

import SwiftUI

// MARK: - Theme Colors

/// 主题颜色配置
/// 包含应用所需的所有颜色定义，支持浅色和深色模式
struct ThemeColors: Codable, Equatable {

    // MARK: - 基础色彩 (3个)

    /// 主背景色
    let background: String

    /// 表面/卡片背景色
    let surface: String

    /// 遮罩层颜色
    let overlay: String

    // MARK: - 文字色彩 (4个)

    /// 主要文字颜色
    let textPrimary: String

    /// 次要文字颜色
    let textSecondary: String

    /// 三级文字颜色（占位符、禁用状态等）
    let textTertiary: String

    /// 禁用文字颜色
    let textDisabled: String

    // MARK: - 语义色彩 (6个)

    /// 强调色（主按钮、链接等）
    let accent: String

    /// 强调色悬浮态
    let accentHover: String

    /// 成功状态颜色
    let success: String

    /// 警告状态颜色
    let warning: String

    /// 错误状态颜色
    let error: String

    /// 信息提示颜色
    let info: String

    // MARK: - 日历特定 (7个)

    /// 今日高亮颜色（边框、标记）
    let todayHighlight: String

    /// 今日背景色
    let todayBackground: String

    /// 选中日期颜色
    let selectedDate: String

    /// 选中日期背景色
    let selectedBackground: String

    /// 周末文字颜色
    let weekendText: String

    /// 节假日文字颜色
    let holidayText: String

    /// 非当前月份日期颜色
    let otherMonthText: String

    // MARK: - 边框与分割 (3个)

    /// 常规边框颜色
    let border: String

    /// 浅色边框颜色
    let borderLight: String

    /// 分割线颜色
    let divider: String

    // MARK: - 交互状态 (3个)

    /// 悬浮背景色
    let hover: String

    /// 按下状态背景色
    let pressed: String

    /// 聚焦边框颜色
    let focus: String

    // MARK: - 事件指示 (4个)

    /// 工作事件颜色
    let eventWork: String

    /// 个人事件颜色
    let eventPersonal: String

    /// 节假日事件颜色
    let eventHoliday: String

    /// 其他事件颜色
    let eventOther: String

    // MARK: - Convenience Color Properties

    /// 便捷访问：背景色
    var backgroundColor: Color { Color(hex: background) }

    /// 便捷访问：表面色
    var surfaceColor: Color { Color(hex: surface) }

    /// 便捷访问：遮罩色
    var overlayColor: Color { Color(hex: overlay) }

    /// 便捷访问：主文本色
    var textPrimaryColor: Color { Color(hex: textPrimary) }

    /// 便捷访问：次文本色
    var textSecondaryColor: Color { Color(hex: textSecondary) }

    /// 便捷访问：三级文本色
    var textTertiaryColor: Color { Color(hex: textTertiary) }

    /// 便捷访问：禁用文本色
    var textDisabledColor: Color { Color(hex: textDisabled) }

    /// 便捷访问：强调色
    var accentColor: Color { Color(hex: accent) }

    /// 便捷访问：强调色悬浮态
    var accentHoverColor: Color { Color(hex: accentHover) }

    /// 便捷访问：成功色
    var successColor: Color { Color(hex: success) }

    /// 便捷访问：警告色
    var warningColor: Color { Color(hex: warning) }

    /// 便捷访问：错误色
    var errorColor: Color { Color(hex: error) }

    /// 便捷访问：信息色
    var infoColor: Color { Color(hex: info) }

    /// 便捷访问：今日高亮色
    var todayHighlightColor: Color { Color(hex: todayHighlight) }

    /// 便捷访问：今日背景色
    var todayBackgroundColor: Color { Color(hex: todayBackground) }

    /// 便捷访问：选中日期色
    var selectedDateColor: Color { Color(hex: selectedDate) }

    /// 便捷访问：选中背景色
    var selectedBackgroundColor: Color { Color(hex: selectedBackground) }

    /// 便捷访问：周末文字色
    var weekendTextColor: Color { Color(hex: weekendText) }

    /// 便捷访问：节假日文字色
    var holidayTextColor: Color { Color(hex: holidayText) }

    /// 便捷访问：非当前月文字色
    var otherMonthTextColor: Color { Color(hex: otherMonthText) }

    /// 便捷访问：边框色
    var borderColor: Color { Color(hex: border) }

    /// 便捷访问：浅色边框
    var borderLightColor: Color { Color(hex: borderLight) }

    /// 便捷访问：分割线色
    var dividerColor: Color { Color(hex: divider) }

    /// 便捷访问：悬浮色
    var hoverColor: Color { Color(hex: hover) }

    /// 便捷访问：按下色
    var pressedColor: Color { Color(hex: pressed) }

    /// 便捷访问：聚焦色
    var focusColor: Color { Color(hex: focus) }

    /// 便捷访问：工作事件色
    var eventWorkColor: Color { Color(hex: eventWork) }

    /// 便捷访问：个人事件色
    var eventPersonalColor: Color { Color(hex: eventPersonal) }

    /// 便捷访问：节假日事件色
    var eventHolidayColor: Color { Color(hex: eventHoliday) }

    /// 便捷访问：其他事件色
    var eventOtherColor: Color { Color(hex: eventOther) }

    // MARK: - 兼容旧代码的属性

    /// 兼容旧代码：文本颜色
    var textColor: Color { textPrimaryColor }

    /// 兼容旧代码：次要文本颜色
    var secondaryTextColor: Color { textSecondaryColor }

    // MARK: - Predefined Color Sets

    /// 预设浅色主题颜色（经典蓝配色）
    static let light = ThemeColors(
        // 基础色彩
        background: "#FFFFFF",
        surface: "#F8F9FA",
        overlay: "#00000033",

        // 文字色彩
        textPrimary: "#202124",
        textSecondary: "#5F6368",
        textTertiary: "#80868B",
        textDisabled: "#DADCE0",

        // 语义色彩
        accent: "#1A73E8",
        accentHover: "#1557B0",
        success: "#34A853",
        warning: "#F9AB00",
        error: "#EA4335",
        info: "#4285F4",

        // 日历特定
        todayHighlight: "#1A73E8",
        todayBackground: "#1A73E81F",
        selectedDate: "#1A73E8",
        selectedBackground: "#1A73E826",
        weekendText: "#EA4335",
        holidayText: "#EA4335",
        otherMonthText: "#80868B",

        // 边框与分割
        border: "#DADCE0",
        borderLight: "#F1F3F4",
        divider: "#E8EAED",

        // 交互状态
        hover: "#5F636814",
        pressed: "#5F63681F",
        focus: "#1A73E8",

        // 事件指示
        eventWork: "#1A73E8",
        eventPersonal: "#34A853",
        eventHoliday: "#EA4335",
        eventOther: "#80868B"
    )

    /// 预设深色主题颜色（午夜蓝配色）
    static let dark = ThemeColors(
        // 基础色彩
        background: "#1C1C1E",
        surface: "#2C2C2E",
        overlay: "#FFFFFF33",

        // 文字色彩
        textPrimary: "#F5F5F7",
        textSecondary: "#AEAEB2",
        textTertiary: "#8E8E93",
        textDisabled: "#48484A",

        // 语义色彩
        accent: "#0A84FF",
        accentHover: "#409CFF",
        success: "#32D74B",
        warning: "#FF9F0A",
        error: "#FF453A",
        info: "#64D2FF",

        // 日历特定
        todayHighlight: "#0A84FF",
        todayBackground: "#0A84FF1F",
        selectedDate: "#0A84FF",
        selectedBackground: "#0A84FF26",
        weekendText: "#FF6B6B",
        holidayText: "#FF453A",
        otherMonthText: "#8E8E93",

        // 边框与分割
        border: "#38383A",
        borderLight: "#2C2C2E",
        divider: "#48484A",

        // 交互状态
        hover: "#AEAEB214",
        pressed: "#AEAEB21F",
        focus: "#0A84FF",

        // 事件指示
        eventWork: "#0A84FF",
        eventPersonal: "#32D74B",
        eventHoliday: "#FF453A",
        eventOther: "#8E8E93"
    )
}

// MARK: - Color Extension

extension Color {
    /// 从十六进制字符串创建颜色
    /// - Parameter hex: 十六进制颜色字符串，支持 #RGB, #RRGGBB, #AARRGGBB 格式
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
