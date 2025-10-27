//
//  Theme.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct Theme: Identifiable, Codable {
    let id: String
    let name: String
    let colors: ThemeColors
    let isSystemTheme: Bool

    static let light = Theme(
        id: "light",
        name: "浅色",
        colors: ThemeColors.light,
        isSystemTheme: false
    )

    static let dark = Theme(
        id: "dark",
        name: "深色",
        colors: ThemeColors.dark,
        isSystemTheme: false
    )

    static let system = Theme(
        id: "system",
        name: "跟随系统",
        colors: ThemeColors.light,
        isSystemTheme: true
    )
}
