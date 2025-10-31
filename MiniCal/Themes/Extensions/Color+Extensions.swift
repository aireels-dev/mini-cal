//
//  Color+Extensions.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI
import Foundation

// MARK: - Color Extensions

extension Color {
    /// 从HEX字符串创建Color
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// 转换为HEX字符串
    func toHex() -> String {
        let uiColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }

    /// 创建颜色变体（ lighter/darker）
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        self.adjustBrightness(by: percentage)
    }

    func darker(by percentage: CGFloat = 0.2) -> Color {
        self.adjustBrightness(by: -percentage)
    }

    private func adjustBrightness(by percentage: CGFloat) -> Color {
        let uiColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newBrightness = max(0, min(1, brightness + percentage))

        return Color(
            hue: hue,
            saturation: saturation,
            brightness: newBrightness,
            opacity: alpha
        )
    }

    /// 获取颜色的亮度
    func luminance() -> Double {
        let uiColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // 相对亮度计算 (sRGB)
        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// 判断是否为深色
    func isDark() -> Bool {
        return luminance() < 0.5
    }

    /// 计算与另一个颜色的对比度
    func contrastRatio(with other: Color) -> CGFloat {
        let l1 = self.luminance()
        let l2 = other.luminance()

        let lighter = max(l1, l2)
        let darker = min(l1, l2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// 获取适合的文本颜色（黑色或白色）
    func contrastingTextColor() -> Color {
        return self.isDark() ? Color.white : Color.black
    }
}

// MARK: - ColorSet Extensions

extension ColorSet {
    /// 获取主要颜色
    var primaryColor: Color {
        return Color(hex: main)
    }

    /// 根据主题获取适当的颜色变体
    func colorForAppearance(_ appearance: NSAppearance.Name? = nil) -> Color {
        if let appearance = appearance {
            switch appearance {
            case .darkAqua, .vibrantDark:
                return dark != nil ? Color(hex: dark!) : Color(hex: main)
            default:
                return light != nil ? Color(hex: light!) : Color(hex: main)
            }
        }

        // 如果没有指定外观，返回主要颜色
        return Color(hex: main)
    }

    /// 获取带透明度的颜色
    func colorWithAlpha(_ alpha: Double) -> Color {
        return Color(hex: main).opacity(alpha)
    }
}

// MARK: - NSColor Extensions

extension NSColor {
    /// 从HEX字符串创建NSColor
    convenience init(hex: String) {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

extension NSColor {
    /// 从HEX字符串创建NSColor
    static func from(hex: String) -> NSColor {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        return NSColor(
            calibratedRed: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }

    /// 转换为HEX字符串
    func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
}

// MARK: - Theme Color Utilities

struct ThemeColorUtils {
    /// 从ColorSet创建SwiftUI颜色
    static func color(from colorSet: ColorSet, appearance: NSAppearance.Name? = nil) -> Color {
        return colorSet.colorForAppearance(appearance)
    }

    /// 创建主题感知的颜色
    static func themedColor(
        light lightHex: String,
        dark darkHex: String,
        appearance: NSAppearance.Name? = nil
    ) -> Color {
        switch appearance {
        case .darkAqua, .vibrantDark:
            return Color(hex: darkHex)
        default:
            return Color(hex: lightHex)
        }
    }

    /// 获取系统主题色
    static func systemAccentColor() -> Color {
        return Color(NSColor.controlAccentColor)
    }

    /// 创建渐变色
    static func gradient(
        from startColor: Color,
        to endColor: Color,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    /// 验证HEX颜色格式
    static func isValidHex(_ hex: String) -> Bool {
        let regex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: hex)
    }

    /// 生成颜色预览数组
    static func previewColors(for theme: ThemeConfiguration) -> [Color] {
        return theme.previewColors.map { Color(hex: $0) }
    }
}

// MARK: - Animation Extensions

extension Animation {
    /// 主题切换动画
    static let themeTransition = Animation.easeInOut(duration: 0.3)

    /// 快速主题切换动画
    static let quickThemeTransition = Animation.easeInOut(duration: 0.15)

    /// 平滑主题切换动画
    static let smoothThemeTransition = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

// MARK: - View Modifiers

struct ThemeAwareModifier: ViewModifier {
    let theme: ThemeConfiguration
    let isAnimated: Bool

    func body(content: Content) -> some View {
        content
            .background(ThemeColorUtils.color(from: theme.background))
            .foregroundColor(Color(hex: theme.text.primary))
            .animation(isAnimated ? .themeTransition : .none, value: theme.id)
    }
}

extension View {
    /// 应用主题
    func themeAware(_ theme: ThemeConfiguration, animated: Bool = true) -> some View {
        modifier(ThemeAwareModifier(theme: theme, isAnimated: animated))
    }

    /// 应用主题背景色
    func themedBackground(_ colorSet: ColorSet, appearance: NSAppearance.Name? = nil) -> some View {
        self.background(ThemeColorUtils.color(from: colorSet, appearance: appearance))
    }

    /// 应用主题前景色
    func themedForeground(_ colorSet: ColorSet, appearance: NSAppearance.Name? = nil) -> some View {
        self.foregroundColor(ThemeColorUtils.color(from: colorSet, appearance: appearance))
    }
}