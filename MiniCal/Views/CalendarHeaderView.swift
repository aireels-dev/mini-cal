//
//  CalendarHeaderView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarHeaderView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let themeColors: ThemeColors

    var body: some View {
        HStack {
            // 上个月按钮
            Button(action: {
                viewModel.goToPreviousMonth()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColors.textColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // 当前月份年份
            Button(action: {
                viewModel.goToToday()
            }) {
                Text(viewModel.monthYearText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColors.textColor)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // 下个月按钮
            Button(action: {
                viewModel.goToNextMonth()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColors.textColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    CalendarHeaderView(
        viewModel: CalendarViewModel(),
        themeColors: .light
    )
    .background(ThemeColors.light.backgroundColor)
}
