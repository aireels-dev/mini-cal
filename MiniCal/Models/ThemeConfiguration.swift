//
//  ThemeConfiguration.swift
//  MiniCal
//
//  Created by MiniCal on 2025/11/13.
//  主题配置和内置主题定义
//

import SwiftUI
import Combine

// MARK: - Theme Mode

/// 主题模式
enum ThemeMode: String, Codable, CaseIterable {
    case light = "light"   // 浅色模式
    case auto = "auto"     // 自动跟随系统
    case dark = "dark"     // 深色模式

    var displayName: String {
        return NSLocalizedString("theme_mode.\(rawValue)", comment: "")
    }

    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .auto: return "circle.lefthalf.filled"
        case .dark: return "moon.stars"
        }
    }

    var description: String {
        return NSLocalizedString("theme_mode.\(rawValue).description", comment: "")
    }
}

// MARK: - Theme Category

/// 主题分类（浅色/深色）
enum ThemeCategory: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"

    var displayName: String {
        return NSLocalizedString("theme_mode.\(rawValue)", comment: "")
    }

    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon.stars"
        }
    }
}

// MARK: - Theme Configuration

/// 主题配置
struct ThemeConfiguration: Identifiable, Codable, Equatable {
    let id: String
    let name: String              // 英文名称
    let displayName: String       // 中文显示名称
    let category: ThemeCategory   // 主题分类
    let colors: ThemeColors       // 完整的颜色配置
    let previewColors: [String]   // 预览颜色（用于主题卡片显示）
    let author: String?           // 作者（可选）
    let version: String           // 版本号

    init(
        id: String,
        name: String,
        displayName: String,
        category: ThemeCategory,
        colors: ThemeColors,
        previewColors: [String],
        author: String? = "MiniCal",
        version: String = "1.0"
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.category = category
        self.colors = colors
        self.previewColors = previewColors
        self.author = author
        self.version = version
    }

    /// 是否为内置主题
    var isBuiltIn: Bool {
        return author == nil || author == "MiniCal"
    }

    /// 本地化的显示名称
    var localizedDisplayName: String {
        return NSLocalizedString("theme.\(id)", comment: "")
    }
}

// MARK: - Built-in Themes

/// 内置主题定义（基于 Chrome 设计的16个主题）
struct BuiltInThemes {

    // MARK: - 浅色主题组 (8个)

    /// 1. 经典蓝 - Google Blue 配色，专业商务
    static let classicBlue = ThemeConfiguration(
        id: "classic_blue",
        name: "Classic Blue",
        displayName: "经典蓝",
        category: .light,
        colors: ThemeColors(
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
        ),
        previewColors: ["#1A73E8", "#4285F4", "#A8C7FA", "#E8F0FE"]
    )

    /// 2. 海洋青 - Cyan 配色，清新现代
    static let oceanTeal = ThemeConfiguration(
        id: "ocean_teal",
        name: "Ocean Teal",
        displayName: "海洋青",
        category: .light,
        colors: ThemeColors(
            background: "#FFFFFF",
            surface: "#F0F9FF",
            overlay: "#00000033",
            textPrimary: "#1C1C1E",
            textSecondary: "#5F6368",
            textTertiary: "#80868B",
            textDisabled: "#DADCE0",
            accent: "#0891B2",
            accentHover: "#0E7490",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#06B6D4",
            todayHighlight: "#0891B2",
            todayBackground: "#0891B21F",
            selectedDate: "#0891B2",
            selectedBackground: "#0891B226",
            weekendText: "#EC4899",
            holidayText: "#EF4444",
            otherMonthText: "#80868B",
            border: "#E0E7FF",
            borderLight: "#F0F9FF",
            divider: "#E8EAED",
            hover: "#0891B214",
            pressed: "#0891B21F",
            focus: "#0891B2",
            eventWork: "#0891B2",
            eventPersonal: "#10B981",
            eventHoliday: "#EF4444",
            eventOther: "#6B7280"
        ),
        previewColors: ["#0891B2", "#06B6D4", "#A5F3FC", "#ECFEFF"]
    )

    /// 3. 翠绿森林 - Emerald 配色，自然健康
    static let forestGreen = ThemeConfiguration(
        id: "forest_green",
        name: "Forest Green",
        displayName: "翠绿森林",
        category: .light,
        colors: ThemeColors(
            background: "#FFFFFF",
            surface: "#F0FDF4",
            overlay: "#00000033",
            textPrimary: "#1C1C1E",
            textSecondary: "#52525B",
            textTertiary: "#71717A",
            textDisabled: "#D4D4D8",
            accent: "#059669",
            accentHover: "#047857",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#06B6D4",
            todayHighlight: "#059669",
            todayBackground: "#0596691F",
            selectedDate: "#059669",
            selectedBackground: "#05966926",
            weekendText: "#F97316",
            holidayText: "#EF4444",
            otherMonthText: "#71717A",
            border: "#D1FAE5",
            borderLight: "#ECFDF5",
            divider: "#E8EAED",
            hover: "#05966914",
            pressed: "#0596691F",
            focus: "#059669",
            eventWork: "#059669",
            eventPersonal: "#10B981",
            eventHoliday: "#EF4444",
            eventOther: "#71717A"
        ),
        previewColors: ["#059669", "#10B981", "#6EE7B7", "#D1FAE5"]
    )

    /// 4. 阳光橙 - Orange 配色，温暖友好
    static let sunsetOrange = ThemeConfiguration(
        id: "sunset_orange",
        name: "Sunset Orange",
        displayName: "阳光橙",
        category: .light,
        colors: ThemeColors(
            background: "#FFFFFF",
            surface: "#FFF7ED",
            overlay: "#00000033",
            textPrimary: "#1C1C1E",
            textSecondary: "#57534E",
            textTertiary: "#78716C",
            textDisabled: "#D6D3D1",
            accent: "#EA580C",
            accentHover: "#C2410C",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#EA580C",
            todayBackground: "#EA580C1F",
            selectedDate: "#EA580C",
            selectedBackground: "#EA580C26",
            weekendText: "#DC2626",
            holidayText: "#DC2626",
            otherMonthText: "#78716C",
            border: "#FED7AA",
            borderLight: "#FFEDD5",
            divider: "#E8EAED",
            hover: "#EA580C14",
            pressed: "#EA580C1F",
            focus: "#EA580C",
            eventWork: "#EA580C",
            eventPersonal: "#10B981",
            eventHoliday: "#DC2626",
            eventOther: "#78716C"
        ),
        previewColors: ["#EA580C", "#F97316", "#FED7AA", "#FFEDD5"]
    )

    /// 5. 玫瑰粉 - Rose 配色，优雅柔和
    static let rosePink = ThemeConfiguration(
        id: "rose_pink",
        name: "Rose Pink",
        displayName: "玫瑰粉",
        category: .light,
        colors: ThemeColors(
            background: "#FFFFFF",
            surface: "#FFF1F2",
            overlay: "#00000033",
            textPrimary: "#1C1C1E",
            textSecondary: "#57534E",
            textTertiary: "#78716C",
            textDisabled: "#D6D3D1",
            accent: "#E11D48",
            accentHover: "#BE123C",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#DC2626",
            info: "#3B82F6",
            todayHighlight: "#E11D48",
            todayBackground: "#E11D481F",
            selectedDate: "#E11D48",
            selectedBackground: "#E11D4826",
            weekendText: "#DC2626",
            holidayText: "#DC2626",
            otherMonthText: "#78716C",
            border: "#FECDD3",
            borderLight: "#FFE4E6",
            divider: "#E8EAED",
            hover: "#E11D4814",
            pressed: "#E11D481F",
            focus: "#E11D48",
            eventWork: "#E11D48",
            eventPersonal: "#10B981",
            eventHoliday: "#DC2626",
            eventOther: "#78716C"
        ),
        previewColors: ["#E11D48", "#F43F5E", "#FECDD3", "#FFE4E6"]
    )

    /// 6. 薰衣草紫 - Purple 配色，神秘优雅
    static let lavenderPurple = ThemeConfiguration(
        id: "lavender_purple",
        name: "Lavender Purple",
        displayName: "薰衣草紫",
        category: .light,
        colors: ThemeColors(
            background: "#FFFFFF",
            surface: "#FAF5FF",
            overlay: "#00000033",
            textPrimary: "#1C1C1E",
            textSecondary: "#52525B",
            textTertiary: "#71717A",
            textDisabled: "#D4D4D8",
            accent: "#9333EA",
            accentHover: "#7E22CE",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#9333EA",
            todayBackground: "#9333EA1F",
            selectedDate: "#9333EA",
            selectedBackground: "#9333EA26",
            weekendText: "#EC4899",
            holidayText: "#EF4444",
            otherMonthText: "#71717A",
            border: "#E9D5FF",
            borderLight: "#F3E8FF",
            divider: "#E8EAED",
            hover: "#9333EA14",
            pressed: "#9333EA1F",
            focus: "#9333EA",
            eventWork: "#9333EA",
            eventPersonal: "#10B981",
            eventHoliday: "#EF4444",
            eventOther: "#71717A"
        ),
        previewColors: ["#9333EA", "#A855F7", "#D8B4FE", "#E9D5FF"]
    )

    /// 7. 天空蓝 - Sky 配色，清爽明快
    static let skyBlue = ThemeConfiguration(
        id: "sky_blue",
        name: "Sky Blue",
        displayName: "天空蓝",
        category: .light,
        colors: ThemeColors(
            background: "#FFFFFF",
            surface: "#F0F9FF",
            overlay: "#00000033",
            textPrimary: "#1C1C1E",
            textSecondary: "#475569",
            textTertiary: "#64748B",
            textDisabled: "#CBD5E1",
            accent: "#0284C7",
            accentHover: "#0369A1",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#06B6D4",
            todayHighlight: "#0284C7",
            todayBackground: "#0284C71F",
            selectedDate: "#0284C7",
            selectedBackground: "#0284C726",
            weekendText: "#EF4444",
            holidayText: "#DC2626",
            otherMonthText: "#64748B",
            border: "#BAE6FD",
            borderLight: "#E0F2FE",
            divider: "#E8EAED",
            hover: "#0284C714",
            pressed: "#0284C71F",
            focus: "#0284C7",
            eventWork: "#0284C7",
            eventPersonal: "#10B981",
            eventHoliday: "#EF4444",
            eventOther: "#64748B"
        ),
        previewColors: ["#0284C7", "#0EA5E9", "#BAE6FD", "#E0F2FE"]
    )

    /// 8. 中性灰 - Neutral 配色，简约专业
    static let neutralGray = ThemeConfiguration(
        id: "neutral_gray",
        name: "Neutral Gray",
        displayName: "中性灰",
        category: .light,
        colors: ThemeColors(
            background: "#FAFAFA",
            surface: "#F5F5F5",
            overlay: "#00000033",
            textPrimary: "#171717",
            textSecondary: "#525252",
            textTertiary: "#737373",
            textDisabled: "#D4D4D4",
            accent: "#525252",
            accentHover: "#404040",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#525252",
            todayBackground: "#5252521F",
            selectedDate: "#525252",
            selectedBackground: "#52525226",
            weekendText: "#DC2626",
            holidayText: "#DC2626",
            otherMonthText: "#A3A3A3",
            border: "#E5E5E5",
            borderLight: "#F5F5F5",
            divider: "#E8EAED",
            hover: "#52525214",
            pressed: "#5252521F",
            focus: "#525252",
            eventWork: "#525252",
            eventPersonal: "#10B981",
            eventHoliday: "#DC2626",
            eventOther: "#737373"
        ),
        previewColors: ["#525252", "#737373", "#D4D4D4", "#F5F5F5"]
    )

    // MARK: - 深色主题组 (8个)

    /// 9. 午夜蓝 - iOS Blue Dark 配色，深沉专业
    static let midnightBlue = ThemeConfiguration(
        id: "midnight_blue",
        name: "Midnight Blue",
        displayName: "午夜蓝",
        category: .dark,
        colors: ThemeColors(
            background: "#1C1C1E",
            surface: "#2C2C2E",
            overlay: "#FFFFFF33",
            textPrimary: "#F5F5F7",
            textSecondary: "#AEAEB2",
            textTertiary: "#8E8E93",
            textDisabled: "#48484A",
            accent: "#0A84FF",
            accentHover: "#409CFF",
            success: "#32D74B",
            warning: "#FF9F0A",
            error: "#FF453A",
            info: "#64D2FF",
            todayHighlight: "#0A84FF",
            todayBackground: "#0A84FF1F",
            selectedDate: "#0A84FF",
            selectedBackground: "#0A84FF26",
            weekendText: "#FF6B6B",
            holidayText: "#FF453A",
            otherMonthText: "#8E8E93",
            border: "#38383A",
            borderLight: "#2C2C2E",
            divider: "#48484A",
            hover: "#AEAEB214",
            pressed: "#AEAEB21F",
            focus: "#0A84FF",
            eventWork: "#0A84FF",
            eventPersonal: "#32D74B",
            eventHoliday: "#FF453A",
            eventOther: "#8E8E93"
        ),
        previewColors: ["#0A84FF", "#409CFF", "#2C2C2E", "#1C1C1E"]
    )

    /// 10. 深海青 - Cyan 深色配色，沉稳现代
    static let deepTeal = ThemeConfiguration(
        id: "deep_teal",
        name: "Deep Teal",
        displayName: "深海青",
        category: .dark,
        colors: ThemeColors(
            background: "#1A1F2E",
            surface: "#252D3F",
            overlay: "#FFFFFF33",
            textPrimary: "#E2E8F0",
            textSecondary: "#94A3B8",
            textTertiary: "#64748B",
            textDisabled: "#334155",
            accent: "#06B6D4",
            accentHover: "#22D3EE",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#06B6D4",
            todayBackground: "#06B6D41F",
            selectedDate: "#06B6D4",
            selectedBackground: "#06B6D426",
            weekendText: "#F472B6",
            holidayText: "#F87171",
            otherMonthText: "#64748B",
            border: "#334155",
            borderLight: "#252D3F",
            divider: "#3F4D5F",
            hover: "#94A3B814",
            pressed: "#94A3B81F",
            focus: "#06B6D4",
            eventWork: "#06B6D4",
            eventPersonal: "#10B981",
            eventHoliday: "#F87171",
            eventOther: "#64748B"
        ),
        previewColors: ["#06B6D4", "#22D3EE", "#252D3F", "#1A1F2E"]
    )

    /// 11. 暗夜绿 - Emerald 深色配色，自然宁静
    static let darkGreen = ThemeConfiguration(
        id: "dark_green",
        name: "Dark Green",
        displayName: "暗夜绿",
        category: .dark,
        colors: ThemeColors(
            background: "#1A1D1A",
            surface: "#252D25",
            overlay: "#FFFFFF33",
            textPrimary: "#E8F5E9",
            textSecondary: "#A5D6A7",
            textTertiary: "#81C784",
            textDisabled: "#2E7D32",
            accent: "#10B981",
            accentHover: "#34D399",
            success: "#22C55E",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#10B981",
            todayBackground: "#10B9811F",
            selectedDate: "#10B981",
            selectedBackground: "#10B98126",
            weekendText: "#FB923C",
            holidayText: "#F87171",
            otherMonthText: "#81C784",
            border: "#2E4F2E",
            borderLight: "#252D25",
            divider: "#3A523A",
            hover: "#A5D6A714",
            pressed: "#A5D6A71F",
            focus: "#10B981",
            eventWork: "#10B981",
            eventPersonal: "#22C55E",
            eventHoliday: "#F87171",
            eventOther: "#81C784"
        ),
        previewColors: ["#10B981", "#34D399", "#252D25", "#1A1D1A"]
    )

    /// 12. 琥珀橙 - Amber 深色配色，温暖舒适
    static let amberOrange = ThemeConfiguration(
        id: "amber_orange",
        name: "Amber Orange",
        displayName: "琥珀橙",
        category: .dark,
        colors: ThemeColors(
            background: "#1F1A15",
            surface: "#2D2519",
            overlay: "#FFFFFF33",
            textPrimary: "#FEF3C7",
            textSecondary: "#FCD34D",
            textTertiary: "#F59E0B",
            textDisabled: "#78350F",
            accent: "#F59E0B",
            accentHover: "#FBBF24",
            success: "#10B981",
            warning: "#F97316",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#F59E0B",
            todayBackground: "#F59E0B1F",
            selectedDate: "#F59E0B",
            selectedBackground: "#F59E0B26",
            weekendText: "#FB923C",
            holidayText: "#F87171",
            otherMonthText: "#F59E0B",
            border: "#44300D",
            borderLight: "#2D2519",
            divider: "#573B1A",
            hover: "#FCD34D14",
            pressed: "#FCD34D1F",
            focus: "#F59E0B",
            eventWork: "#F59E0B",
            eventPersonal: "#10B981",
            eventHoliday: "#F87171",
            eventOther: "#F59E0B"
        ),
        previewColors: ["#F59E0B", "#FBBF24", "#2D2519", "#1F1A15"]
    )

    /// 13. 暗紫红 - Pink 深色配色，优雅神秘
    static let darkMagenta = ThemeConfiguration(
        id: "dark_magenta",
        name: "Dark Magenta",
        displayName: "暗紫红",
        category: .dark,
        colors: ThemeColors(
            background: "#1F1825",
            surface: "#2D2035",
            overlay: "#FFFFFF33",
            textPrimary: "#FCE7F3",
            textSecondary: "#F9A8D4",
            textTertiary: "#F472B6",
            textDisabled: "#831843",
            accent: "#DB2777",
            accentHover: "#F472B6",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#DB2777",
            todayBackground: "#DB27771F",
            selectedDate: "#DB2777",
            selectedBackground: "#DB277726",
            weekendText: "#F87171",
            holidayText: "#F87171",
            otherMonthText: "#F472B6",
            border: "#500724",
            borderLight: "#2D2035",
            divider: "#6B0F3B",
            hover: "#F9A8D414",
            pressed: "#F9A8D41F",
            focus: "#DB2777",
            eventWork: "#DB2777",
            eventPersonal: "#10B981",
            eventHoliday: "#F87171",
            eventOther: "#F472B6"
        ),
        previewColors: ["#DB2777", "#F472B6", "#2D2035", "#1F1825"]
    )

    /// 14. 深邃紫 - Violet 深色配色，高贵创意
    static let deepPurple = ThemeConfiguration(
        id: "deep_purple",
        name: "Deep Purple",
        displayName: "深邃紫",
        category: .dark,
        colors: ThemeColors(
            background: "#1A1625",
            surface: "#251F35",
            overlay: "#FFFFFF33",
            textPrimary: "#EDE9FE",
            textSecondary: "#C4B5FD",
            textTertiary: "#A78BFA",
            textDisabled: "#4C1D95",
            accent: "#8B5CF6",
            accentHover: "#A78BFA",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#8B5CF6",
            todayBackground: "#8B5CF61F",
            selectedDate: "#8B5CF6",
            selectedBackground: "#8B5CF626",
            weekendText: "#F472B6",
            holidayText: "#F87171",
            otherMonthText: "#A78BFA",
            border: "#3F2F5F",
            borderLight: "#251F35",
            divider: "#4C3A73",
            hover: "#C4B5FD14",
            pressed: "#C4B5FD1F",
            focus: "#8B5CF6",
            eventWork: "#8B5CF6",
            eventPersonal: "#10B981",
            eventHoliday: "#F87171",
            eventOther: "#A78BFA"
        ),
        previewColors: ["#8B5CF6", "#A78BFA", "#251F35", "#1A1625"]
    )

    /// 15. 靛蓝紫 - Indigo 深色配色，现代科技
    static let indigoPurple = ThemeConfiguration(
        id: "indigo_purple",
        name: "Indigo Purple",
        displayName: "靛蓝紫",
        category: .dark,
        colors: ThemeColors(
            background: "#1E1B2E",
            surface: "#2A2640",
            overlay: "#FFFFFF33",
            textPrimary: "#E0E7FF",
            textSecondary: "#A5B4FC",
            textTertiary: "#818CF8",
            textDisabled: "#3730A3",
            accent: "#6366F1",
            accentHover: "#818CF8",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#6366F1",
            todayBackground: "#6366F11F",
            selectedDate: "#6366F1",
            selectedBackground: "#6366F126",
            weekendText: "#C084FC",
            holidayText: "#F87171",
            otherMonthText: "#818CF8",
            border: "#3F3B5F",
            borderLight: "#2A2640",
            divider: "#4C4673",
            hover: "#A5B4FC14",
            pressed: "#A5B4FC1F",
            focus: "#6366F1",
            eventWork: "#6366F1",
            eventPersonal: "#10B981",
            eventHoliday: "#F87171",
            eventOther: "#818CF8"
        ),
        previewColors: ["#6366F1", "#818CF8", "#2A2640", "#1E1B2E"]
    )

    /// 16. 石墨灰 - Gray 深色配色，专业低调
    static let graphiteGray = ThemeConfiguration(
        id: "graphite_gray",
        name: "Graphite Gray",
        displayName: "石墨灰",
        category: .dark,
        colors: ThemeColors(
            background: "#1C1C1E",
            surface: "#2C2C2E",
            overlay: "#FFFFFF33",
            textPrimary: "#E8EAED",
            textSecondary: "#BDC1C6",
            textTertiary: "#9AA0A6",
            textDisabled: "#5F6368",
            accent: "#8E8E93",
            accentHover: "#AEAEB2",
            success: "#10B981",
            warning: "#F59E0B",
            error: "#EF4444",
            info: "#3B82F6",
            todayHighlight: "#AEAEB2",
            todayBackground: "#AEAEB21F",
            selectedDate: "#AEAEB2",
            selectedBackground: "#AEAEB226",
            weekendText: "#FF6B6B",
            holidayText: "#F87171",
            otherMonthText: "#9AA0A6",
            border: "#3C4043",
            borderLight: "#2C2C2E",
            divider: "#48484A",
            hover: "#BDC1C614",
            pressed: "#BDC1C61F",
            focus: "#AEAEB2",
            eventWork: "#8E8E93",
            eventPersonal: "#10B981",
            eventHoliday: "#F87171",
            eventOther: "#9AA0A6"
        ),
        previewColors: ["#8E8E93", "#AEAEB2", "#2C2C2E", "#1C1C1E"]
    )

    // MARK: - Collections

    /// 所有浅色主题
    static var lightThemes: [ThemeConfiguration] {
        [
            classicBlue,
            oceanTeal,
            forestGreen,
            sunsetOrange,
            rosePink,
            lavenderPurple,
            skyBlue,
            neutralGray
        ]
    }

    /// 所有深色主题
    static var darkThemes: [ThemeConfiguration] {
        [
            midnightBlue,
            deepTeal,
            darkGreen,
            amberOrange,
            darkMagenta,
            deepPurple,
            indigoPurple,
            graphiteGray
        ]
    }

    /// 所有主题
    static var allThemes: [ThemeConfiguration] {
        lightThemes + darkThemes
    }

    /// 默认浅色主题
    static var defaultLightTheme: ThemeConfiguration {
        classicBlue
    }

    /// 默认深色主题
    static var defaultDarkTheme: ThemeConfiguration {
        midnightBlue
    }
}
