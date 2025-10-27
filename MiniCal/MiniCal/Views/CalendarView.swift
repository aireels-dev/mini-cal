//
//  CalendarView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @StateObject private var settingsManager = SettingsManager()

    private var currentTheme: Theme {
        let themeId = settingsManager.currentSettings.themeId
        switch themeId {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return .system
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 日历头部
            CalendarHeaderView(
                viewModel: viewModel,
                themeColors: currentTheme.colors
            )

            Divider()
                .background(currentTheme.colors.borderColor)

            // 日历网格
            CalendarGridView(
                viewModel: viewModel,
                themeColors: currentTheme.colors
            )
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 380)
        .background(currentTheme.colors.backgroundColor)
    }
}

#Preview {
    CalendarView()
}
