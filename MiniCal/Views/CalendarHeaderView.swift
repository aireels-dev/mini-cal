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
                        // 可选的 icon 方案：
                        // 方案1: "calendar.badge.clock" - 带时钟的日历（推荐）
                        // 方案2: "clock.arrow.circlepath" - 时钟回退
                        // 方案3: "arrow.counterclockwise.circle.fill" - 圆形逆时针
                        // 方案4: "calendar.circle.fill" - 圆形日历
                        // 方案5: "house.circle.fill" - 回到"家"（今天）
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeColors.accentColor.opacity(0.85))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                    .help("回到今天")
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

#Preview {
    CalendarHeaderView(
        viewModel: CalendarViewModel(),
        themeColors: .light
    )
    .background(ThemeColors.light.backgroundColor)
}
