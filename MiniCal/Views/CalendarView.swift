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
        themeManager.effectiveColors
    }

    private var calendarSize: CalendarSize {
        settingsManager.currentSettings.calendarSize
    }

    private var calendarOpacity: Double {
        settingsManager.currentSettings.calendarOpacity
    }

    var body: some View {
        ZStack {
            // 背景层（应用不透明度）
            ZStack {
                // 第一层：Glass 效果背景
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active
                )

                // 第二层：主题表面色 - 使用 surface 而不是 background
                Color(hex: effectiveColors.surface)
                    .opacity(0.92)
            }
            .cornerRadius(12)
            .opacity(calendarOpacity)  // 背景层不透明度

            // 内容层（不应用不透明度，保持文字清晰）
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
        }
        .frame(width: calendarSize.width, height: calendarSize.height)
        .popover(isPresented: $showEventDetail, arrowEdge: .bottom) {
            if let selectedDate = selectedDateForDetail {
                DayEventListView(
                    date: selectedDate.gregorianDate,
                    events: selectedDate.calendarEvents,
                    themeColors: effectiveColors,
                    onEventTap: { event in
                        // 事件点击处理 - 可以显示事件详情
                        print("Event tapped: \(event.title)")
                    },
                    onManageEvents: {
                        // 打开事件管理界面
                        showEventDetail = false
                        // TODO: 打开事件详情/编辑界面
                    }
                )
            }
        }
        .onAppear {
            setupSettingsKeyMonitor()
            setupResetNotification()
        }
        .onDisappear {
            removeSettingsKeyMonitor()
            removeResetNotification()
        }
    }

    // MARK: - Keyboard Shortcuts Monitor

    private func setupSettingsKeyMonitor() {
        // 移除旧监听器（如果存在）
        removeSettingsKeyMonitor()

        // 添加快捷键监听（Command+,, Command+/-, Command+=）
        settingsKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 检查窗口焦点：只在日历浮窗有焦点时响应
            guard self.isCalendarWindowActive() else {
                return event
            }

            // 检查文本输入焦点：避免拦截文本框输入
            if NSApp.keyWindow?.firstResponder as? NSTextView != nil {
                return event
            }

            // 必须按下 Command 键
            guard event.modifierFlags.contains(.command) else {
                return event
            }

            let key = event.charactersIgnoringModifiers ?? ""

            // Command+, 打开设置
            if key == "," {
                self.openSettingsAction?()
                return nil
            }
            // Command+- 减小日历尺寸
            else if key == "-" {
                self.settingsManager.decreaseCalendarSize()
                return nil
            }
            // Command+= 或 Command++ 增大日历尺寸
            else if key == "=" || key == "+" {
                self.settingsManager.increaseCalendarSize()
                return nil
            }

            return event
        }
    }

    /// 检查日历窗口是否处于活动状态
    private func isCalendarWindowActive() -> Bool {
        guard let keyWindow = NSApp.keyWindow else { return false }
        // 检查是否是 NSPopover 的窗口（日历浮窗）
        return keyWindow.className.contains("NSPopover")
    }

    private func removeSettingsKeyMonitor() {
        if let monitor = settingsKeyMonitor {
            NSEvent.removeMonitor(monitor)
            settingsKeyMonitor = nil
        }
    }

    // MARK: - Reset Notification

    private func setupResetNotification() {
        NotificationCenter.default.addObserver(
            forName: .resetCalendarToToday,
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            viewModel?.goToToday()
        }
    }

    private func removeResetNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: .resetCalendarToToday,
            object: nil
        )
    }
}

#Preview {
    CalendarView()
}
