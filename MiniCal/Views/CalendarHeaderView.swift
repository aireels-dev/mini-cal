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
    let calendarSize: CalendarSize
    @State private var hoveredButton: NavButton?

    enum NavButton {
        case previous, next
    }

    var body: some View {
        HStack(spacing: 12) {
            // 上个月按钮
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    viewModel.goToPreviousMonth()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColors.textColor.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(hoveredButton == .previous ?
                                  themeColors.secondaryTextColor.opacity(0.12) :
                                  Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .focusable(false)
            .onHover { isHovered in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredButton = isHovered ? .previous : nil
                }
            }

            Spacer()

            // 中间区域：月份年份 + 回到今天按钮（仅在非当前月份时显示）
            HStack(spacing: 8) {
                // 当前月份年份（点击也可回到今天）
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        viewModel.goToToday()
                    }
                }) {
                    Text(viewModel.monthYearText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeColors.textColor)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)

                // 回到今天的图标按钮（仅在非当前月份时显示）
                if !viewModel.isCurrentMonth {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            viewModel.goToToday()
                        }
                    }) {
                        // 使用应用图标的线稿版本作为"回到今天"图标
                        Image("TodayIcon")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 16, height: 16)
                            .foregroundColor(themeColors.accentColor.opacity(0.85))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                    .help("calendar.back_to_today")
                }
            }

            Spacer()

            // 下个月按钮
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    viewModel.goToNextMonth()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColors.textColor.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(hoveredButton == .next ?
                                  themeColors.secondaryTextColor.opacity(0.12) :
                                  Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .focusable(false)
            .onHover { isHovered in
                withAnimation(.easeInOut(duration: 0.15)) {
                    hoveredButton = isHovered ? .next : nil
                }
            }
        }
        .frame(height: calendarSize.headerHeight, alignment: .center)
        .padding(.horizontal, 16)
    }
}

#Preview {
    CalendarHeaderView(
        viewModel: CalendarViewModel(),
        themeColors: .light,
        calendarSize: .standard
    )
    .background(ThemeColors.light.backgroundColor)
}
