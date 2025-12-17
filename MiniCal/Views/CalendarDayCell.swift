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

    // 计算可用的文字宽度（单元格宽度减去左右padding）
    private var availableTextWidth: CGFloat {
        let cellWidth = calendarSize.width / 7  // 7列
        return cellWidth - 12  // 减去左右padding (6 * 2)
    }

    var body: some View {
        Button(action: onTap) {
            // 主要内容 - 垂直布局（紧贴内容）
            VStack(spacing: 2.5) {
                // 公历日期（加粗提升层级）
                Text("\(date.day)")
                    .font(.system(size: calendarSize.dateFontSize, weight: date.isToday ? .bold : .semibold))
                    .foregroundColor(textColor)

                // 副历日期
                if let secondaryDate = date.secondaryDate {
                    // 优先级：公历节日 > 农历节日 > 常规日期文本
                    if let solarFestival = secondaryDate.solarFestival {
                        // 公历节日（全局显示）- 使用滚动文本
                        ScrollingText(
                            text: solarFestival,
                            font: .system(size: calendarSize.secondaryFontSize - 0.5, weight: .medium),
                            foregroundColor: festivalColor(
                                for: solarFestival,
                                festivalID: secondaryDate.solarFestivalID,
                                calendarType: .gregorian
                            ),
                            maxWidth: availableTextWidth
                        )
                        .frame(height: calendarSize.secondaryFontSize - 0.5)
                    } else if let festival = secondaryDate.festival {
                        // 农历节日或其他历法节日 - 使用滚动文本
                        ScrollingText(
                            text: festival,
                            font: .system(size: calendarSize.secondaryFontSize - 0.5, weight: .medium),
                            foregroundColor: festivalColor(
                                for: festival,
                                festivalID: secondaryDate.festivalID,
                                calendarType: secondaryDate.calendarType
                            ),
                            maxWidth: availableTextWidth
                        )
                        .frame(height: calendarSize.secondaryFontSize - 0.5)
                    } else {
                        // 常规日期文本 - 使用滚动文本
                        ScrollingText(
                            text: secondaryDate.displayText,
                            font: .system(size: calendarSize.secondaryFontSize - 0.5, weight: .light),
                            foregroundColor: themeColors.secondaryTextColor.opacity(0.6),
                            maxWidth: availableTextWidth
                        )
                        .frame(height: calendarSize.secondaryFontSize - 0.5)
                    }
                } else {
                    // 占位空间，保持布局一致
                    Spacer()
                        .frame(height: calendarSize.secondaryFontSize - 0.5)
                }

                // 事件指示器 - 放在农历下方
                if date.hasEvents {
                    EventIndicatorView(
                        eventIndicators: date.eventColors,
                        maxVisible: 3
                    )
                } else {
                    // 占位空间，保持所有单元格高度一致
                    Spacer()
                        .frame(height: 5.5)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 0)
            .background(backgroundColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: date.isToday ? 2 : 0)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: isHovered ? Color.black.opacity(0.15) : Color.clear, radius: 8, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)  // 禁用焦点环，去除蓝色边框
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Button占满单元格，但内容区域紧凑
        .contentShape(Rectangle())  // 整个单元格可点击
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

    /// 根据节日类型返回不同的颜色
    /// - Parameters:
    ///   - festival: 节日显示名称
    ///   - festivalID: 节日唯一标识符（用于程序判断，语言无关）
    ///   - calendarType: 历法类型
    /// - Returns: 节日颜色
    private func festivalColor(for festival: String, festivalID: String?, calendarType: CalendarType) -> Color {
        // 优先使用 festivalID 进行判断（语言无关）
        if let id = festivalID {
            // 二十四节气用绿色
            if id.hasPrefix("solar_term_") {
                return Color.green.opacity(0.85)
            }

            // 特定节日的特殊颜色
            switch id {
            case "shabbat":
                return Color.purple.opacity(0.85)
            case "spring_festival", "mid_autumn":
                return Color.orange.opacity(0.9)
            case "eid_al_fitr", "eid_al_adha":
                return Color.blue.opacity(0.85)
            default:
                break
            }
        }

        // Fallback: 二十四节气字符串判断（兼容旧数据）
        if SolarTermService.shared.isSolarTerm(festival) {
            return Color.green.opacity(0.85)
        }

        // 根据历法类型区分颜色
        switch calendarType {
        case .gregorian:
            // 公历节日用红色（西方节日，圣诞、情人节等）
            return Color.red.opacity(0.85)

        case .chinese:
            // 农历传统节日用橙色
            return Color.orange.opacity(0.9)

        case .islamic:
            // 伊斯兰节日用蓝色
            return Color.blue.opacity(0.85)

        case .hebrew:
            // 犹太节日用靛蓝色
            return Color.indigo.opacity(0.85)

        default:
            // 其他节日用橙色
            return Color.orange.opacity(0.9)
        }
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
