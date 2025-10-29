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
    let calendarSize: CalendarSize
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                // 公历日期（加粗提升层级）
                Text("\(date.day)")
                    .font(.system(size: calendarSize.dateFontSize, weight: date.isToday ? .bold : .semibold))
                    .foregroundColor(textColor)

                // 副历日期或事件指示点
                if let secondaryDate = date.secondaryDate {
                    // 如果有节日，显示节日名称并高亮
                    if let festival = secondaryDate.festival {
                        Text(festival)
                            .font(.system(size: calendarSize.secondaryFontSize, weight: .medium))
                            .foregroundColor(Color.orange.opacity(0.9))
                            .lineLimit(1)
                    } else {
                        Text(secondaryDate.displayText)
                            .font(.system(size: calendarSize.secondaryFontSize, weight: .light))
                            .foregroundColor(themeColors.secondaryTextColor.opacity(0.6))
                            .lineLimit(1)
                    }
                } else if !date.events.isEmpty {
                    // 圆润的事件指示器（胶囊形状）
                    HStack(spacing: 3) {
                        ForEach(date.events.prefix(3)) { event in
                            Capsule()
                                .fill(event.color.swiftUIColor.opacity(0.8))
                                .frame(width: calendarSize.eventIndicatorSize * 1.5,
                                       height: calendarSize.eventIndicatorSize)
                                .shadow(color: event.color.swiftUIColor.opacity(0.3), radius: 1, y: 0.5)
                        }
                    }
                    .padding(.bottom, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: date.isToday ? 2 : 0)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: isHovered ? Color.black.opacity(0.15) : Color.clear, radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered = hovering
            }
        }
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
            return themeColors.accentColor.opacity(0.15)
        }
        if date.isToday {
            // 今日使用更柔和的背景色
            return themeColors.todayHighlightColor.opacity(0.12)
        }
        if isHovered {
            // 悬浮态使用微妙的背景
            return themeColors.secondaryTextColor.opacity(0.08)
        }
        return Color.clear
    }

    private var borderColor: Color {
        if date.isToday {
            // 今日边框使用渐变效果的颜色
            return themeColors.todayHighlightColor.opacity(0.6)
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
        calendarSize: .standard,
        onTap: {}
    )
    .frame(width: 40, height: 40)
}
