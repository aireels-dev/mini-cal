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

    var openSettingsAction: (() -> Void)?

    private var effectiveColors: ThemeColors {
        // 使用ThemeManager获取当前有效的主题颜色（处理系统跟随）
        themeManager.effectiveColors()
    }

    var body: some View {
        VStack(spacing: 0) {
            // 日历头部
            CalendarHeaderView(
                viewModel: viewModel,
                themeColors: effectiveColors
            )

            Divider()
                .background(effectiveColors.borderColor.opacity(0.3))

            // 日历网格
            CalendarGridView(
                viewModel: viewModel,
                themeColors: effectiveColors,
                onDateTap: { date in
                    selectedDateForDetail = date
                    showEventDetail = true
                }
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 380)
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
            // 设置快捷键
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Command+, 打开设置
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                    openSettingsAction?()
                    return nil
                }
                return event
            }
        }
    }
}

#Preview {
    CalendarView()
}
