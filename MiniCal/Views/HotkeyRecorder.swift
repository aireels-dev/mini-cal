//
//  HotkeyRecorder.swift
//  MiniCal
//
//  Created by MiniCal on 2025/11/14.
//  快捷键录制器 - 使用 KeyboardShortcuts 库
//

import SwiftUI
import KeyboardShortcuts

/// 快捷键录制器视图
/// 使用 KeyboardShortcuts 库提供的 RecorderCocoa 组件
struct HotkeyRecorder: View {
    var body: some View {
        HStack {
            Text("misc.shortcut")
                .foregroundColor(.secondary)

            Spacer()

            // 使用 KeyboardShortcuts 提供的 AppKit 录制器
            KeyboardShortcutRecorderView()
                .frame(height: 28)
        }
    }
}

// MARK: - NSViewRepresentable Wrapper

/// 将 KeyboardShortcuts.RecorderCocoa 包装为 SwiftUI View
struct KeyboardShortcutRecorderView: NSViewRepresentable {
    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleCalendar)
        return recorder
    }

    func updateNSView(_ nsView: KeyboardShortcuts.RecorderCocoa, context: Context) {
        // RecorderCocoa 自动处理更新
    }
}
