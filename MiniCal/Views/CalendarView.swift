//
//  CalendarView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedDateForDetail: CalendarDate?
    @State private var showEventDetail = false
    @State private var settingsKeyMonitor: Any?

    var openSettingsAction: (() -> Void)?

    private var effectiveColors: ThemeColors {
        // 使用ThemeManager获取当前有效的主题颜色（处理系统跟随）
        themeManager.effectiveColors()
    }

    private var calendarSize: CalendarSize {
        settingsManager.currentSettings.calendarSize
    }

    var body: some View {
        VStack(spacing: 0) {
            // 日历头部（通过颜色和间距区分层级）
            CalendarHeaderView(
                viewModel: viewModel,
                themeColors: effectiveColors
            )
            .padding(.bottom, 12)

            // 日历网格
            CalendarGridView(
                viewModel: viewModel,
                themeColors: effectiveColors,
                calendarSize: calendarSize,
                onDateTap: { date in
                    selectedDateForDetail = date
                    showEventDetail = true
                }
            )
            .padding(.bottom, 16)
        }
        .frame(width: calendarSize.width, height: calendarSize.height)
        .sheet(isPresented: $showEventDetail) {
            if let selectedDate = selectedDateForDetail {
                EventDetailView(
                    date: selectedDate,
                    themeColors: effectiveColors,
                    onClose: {
                        showEventDetail = false
                    }
                )
            }
        }
        .background(
            // Glass 效果背景
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
        )
        .onAppear {
            setupSettingsKeyMonitor()
        }
        .onDisappear {
            removeSettingsKeyMonitor()
        }
    }

    // MARK: - Keyboard Shortcuts Monitor

    private func setupSettingsKeyMonitor() {
        // 移除旧监听器（如果存在）
        removeSettingsKeyMonitor()

        // 添加快捷键监听（Command+,, Command+/-, Command+=）
        settingsKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 必须按下 Command 键
            guard event.modifierFlags.contains(.command) else {
                return event
            }

            let key = event.charactersIgnoringModifiers ?? ""

            // Command+, 打开设置
            if key == "," {
                openSettingsAction?()
                return nil
            }
            // Command+- 减小日历尺寸
            else if key == "-" {
                settingsManager.decreaseCalendarSize()
                return nil
            }
            // Command+= 或 Command++ 增大日历尺寸
            else if key == "=" || key == "+" {
                settingsManager.increaseCalendarSize()
                return nil
            }

            return event
        }
    }

    private func removeSettingsKeyMonitor() {
        if let monitor = settingsKeyMonitor {
            NSEvent.removeMonitor(monitor)
            settingsKeyMonitor = nil
        }
    }
}

#Preview {
    CalendarView()
}
