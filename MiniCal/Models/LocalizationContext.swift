//
//  LocalizationContext.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation

/// 本地化上下文
struct LocalizationContext: Codable, Equatable {
    /// 界面语言（可选，如果为 nil 则使用系统语言）
    let interfaceLocale: SupportedLocale?

    /// 历法专用语言（可选，如果为 nil 则使用 effectiveInterfaceLocale）
    let calendarLocale: SupportedLocale?

    /// 获取实际使用的界面语言环境
    var effectiveInterfaceLocale: SupportedLocale {
        return interfaceLocale ?? SupportedLocale.recommend()
    }

    /// 获取实际使用的历法语言环境
    var effectiveCalendarLocale: SupportedLocale {
        return calendarLocale ?? effectiveInterfaceLocale
    }

    /// 是否为 RTL 语言
    var isRTL: Bool {
        return effectiveInterfaceLocale.isRTL
    }

    /// 是否使用系统语言（自动模式）
    var isAutoLanguage: Bool {
        return interfaceLocale == nil
    }

    init(interfaceLocale: SupportedLocale?, calendarLocale: SupportedLocale? = nil) {
        self.interfaceLocale = interfaceLocale
        self.calendarLocale = calendarLocale
    }

    /// 创建默认上下文（自动模式）
    static var `default`: LocalizationContext {
        return LocalizationContext(interfaceLocale: nil)
    }
}
