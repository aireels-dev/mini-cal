//
//  KeyboardShortcutNames.swift
//  MiniCal
//
//  Created on 2025/11/14.
//  定义应用的快捷键名称
//

import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    /// 全局快捷键：显示/隐藏日历
    static let toggleCalendar = Self("toggleCalendar", default: .init(.x, modifiers: [.command, .shift]))
}
