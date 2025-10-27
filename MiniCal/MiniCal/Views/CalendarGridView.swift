//
//  CalendarGridView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let themeColors: ThemeColors

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // 星期标题行
            weekdayHeaderRow

            // 日期网格
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.calendarDates) { date in
                    CalendarDayCell(
                        date: date,
                        isSelected: viewModel.isSelected(date),
                        themeColors: themeColors,
                        onTap: {
                            viewModel.selectDate(date)
                        }
                    )
                    .frame(height: 40)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Week Header

    private var weekdayHeaderRow: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.weekdayHeaders(), id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeColors.secondaryTextColor)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    CalendarGridView(
        viewModel: CalendarViewModel(),
        themeColors: .light
    )
    .frame(width: 300, height: 300)
    .background(ThemeColors.light.backgroundColor)
}
