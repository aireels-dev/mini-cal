//
//  DayEventRow.swift
//  MiniCal
//
//  单个事件行组件
//

import SwiftUI

struct DayEventRow: View {
    let event: CalendarEvent
    let themeColors: ThemeColors
    let calendarSize: CalendarSize
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 事件颜色指示器
                Circle()
                    .fill(event.getDisplayColor())
                    .frame(width: 8, height: 8)

                // 事件信息
                VStack(alignment: .leading, spacing: 4) {
                    // 标题
                    Text(event.title)
                        .font(.system(size: calendarSize.eventListTitleFontSize, weight: .medium))
                        .foregroundColor(themeColors.textColor)
                        .lineLimit(1)

                    // 时间和来源
                    HStack(spacing: 8) {
                        // 时间范围
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                                .foregroundColor(themeColors.secondaryTextColor)

                            Text(timeRangeText)
                                .font(.system(size: calendarSize.eventListSubtitleFontSize))
                                .foregroundColor(themeColors.secondaryTextColor)
                        }

                        // 分隔符
                        Text("·")
                            .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                            .foregroundColor(themeColors.secondaryTextColor.opacity(0.5))

                        // 来源
                        HStack(spacing: 3) {
                            Image(systemName: sourceIcon)
                                .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                                .foregroundColor(themeColors.secondaryTextColor)

                            Text(event.sourceName)
                                .font(.system(size: calendarSize.eventListSubtitleFontSize))
                                .foregroundColor(themeColors.secondaryTextColor)
                        }
                    }
                }

                Spacer()

                // 悬停时显示箭头
                if isHovered {
                    Image(systemName: "chevron.right")
                        .font(.system(size: calendarSize.eventListButtonFontSize))
                        .foregroundColor(themeColors.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? themeColors.backgroundColor.opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)  // 禁用焦点环，去除蓝色边框
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Computed Properties

    private var timeRangeText: String {
        if event.isAllDay {
            return "全天"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"

        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)

        return "\(startTime) - \(endTime)"
    }

    private var sourceIcon: String {
        switch event.source {
        case .builtin:
            return "calendar"
        case .eventKit:
            return "cloud"
        case .external:
            return "link"
        case .user:
            return "person"
        }
    }
}

#Preview {
    let event1 = CalendarEvent(
        title: "团队会议",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        source: .eventKit
    )

    let event2 = CalendarEvent(
        title: "项目截止日期",
        startDate: Calendar.current.startOfDay(for: Date()),
        endDate: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!,
        source: .user
    )

    return VStack(spacing: 0) {
        DayEventRow(
            event: event1,
            themeColors: .light,
            calendarSize: .standard,
            onTap: {}
        )

        Divider()

        DayEventRow(
            event: event2,
            themeColors: .light,
            calendarSize: .standard,
            onTap: {}
        )
    }
    .frame(width: 350)
}
