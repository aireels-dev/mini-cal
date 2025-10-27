//
//  CalendarDayCell.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: CalendarDate
    let isSelected: Bool
    let themeColors: ThemeColors
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // 公历日期
                Text("\(date.day)")
                    .font(.system(size: 14, weight: date.isToday ? .bold : .regular))
                    .foregroundColor(textColor)

                // 副历日期或事件指示点
                if let secondaryDate = date.secondaryDate {
                    // 如果有节日，显示节日名称并高亮
                    if let festival = secondaryDate.festival {
                        Text(festival)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.orange)
                            .lineLimit(1)
                    } else {
                        Text(secondaryDate.displayText)
                            .font(.system(size: 9))
                            .foregroundColor(themeColors.secondaryTextColor)
                            .lineLimit(1)
                    }
                } else if !date.events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(date.events.prefix(3)) { event in
                            Circle()
                                .fill(event.color.swiftUIColor)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: date.isToday ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var textColor: Color {
        if !date.isCurrentMonth {
            return themeColors.secondaryTextColor.opacity(0.5)
        }
        if isWeekend {
            return themeColors.weekendTextColor
        }
        return themeColors.textColor
    }

    private var backgroundColor: Color {
        if isSelected {
            return themeColors.accentColor.opacity(0.2)
        }
        if date.isToday {
            return themeColors.todayHighlightColor.opacity(0.1)
        }
        return Color.clear
    }

    private var borderColor: Color {
        if date.isToday {
            return themeColors.todayHighlightColor
        }
        return Color.clear
    }

    private var isWeekend: Bool {
        return date.weekday == 1 || date.weekday == 7
    }
}

#Preview {
    let testDate = CalendarDate(date: Date(), isCurrentMonth: true)

    CalendarDayCell(
        date: testDate,
        isSelected: false,
        themeColors: .light,
        onTap: {}
    )
    .frame(width: 40, height: 40)
}
