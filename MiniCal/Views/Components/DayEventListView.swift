//
//  DayEventListView.swift
//  MiniCal
//
//  日期事件列表视图
//

import SwiftUI

struct DayEventListView: View {
    let date: Date
    let events: [CalendarEvent]
    let themeColors: ThemeColors
    let onEventTap: (CalendarEvent) -> Void
    let onManageEvents: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            DayEventHeader(date: date, themeColors: themeColors)

            Divider()
                .background(themeColors.borderColor)

            // 事件列表
            if events.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sortedEvents) { event in
                            DayEventRow(
                                event: event,
                                themeColors: themeColors,
                                onTap: {
                                    onEventTap(event)
                                }
                            )

                            if event.id != sortedEvents.last?.id {
                                Divider()
                                    .background(themeColors.borderColor.opacity(0.3))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            }

            Divider()
                .background(themeColors.borderColor)

            // 底部操作区
            bottomActionView
        }
        .frame(width: 350)
        .background(
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(themeColors.secondaryTextColor.opacity(0.5))

            VStack(spacing: 4) {
                Text("这天没有事件")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeColors.textColor)

                Text("享受轻松的一天")
                    .font(.system(size: 12))
                    .foregroundColor(themeColors.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Bottom Action View

    private var bottomActionView: some View {
        HStack {
            Button(action: onManageEvents) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 13))
                    Text("管理事件")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(themeColors.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeColors.accentColor.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // 事件统计
            Text("\(events.count) 个事件")
                .font(.system(size: 11))
                .foregroundColor(themeColors.secondaryTextColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeColors.backgroundColor.opacity(0.3))
    }

    // MARK: - Computed Properties

    /// 排序后的事件列表（全天事件优先，然后按开始时间排序）
    private var sortedEvents: [CalendarEvent] {
        events.sorted { event1, event2 in
            if event1.isAllDay != event2.isAllDay {
                return event1.isAllDay // 全天事件排前面
            }
            return event1.startDate < event2.startDate
        }
    }
}

#Preview {
    let events = [
        CalendarEvent(
            title: "团队站会",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            source: .eventKit
        ),
        CalendarEvent(
            title: "产品评审",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            source: .external
        ),
        CalendarEvent(
            title: "周报总结",
            startDate: Date().addingTimeInterval(14400),
            endDate: Date().addingTimeInterval(18000),
            source: .user
        )
    ]

    return VStack(spacing: 20) {
        // 有事件的情况
        DayEventListView(
            date: Date(),
            events: events,
            themeColors: .light,
            onEventTap: { _ in },
            onManageEvents: {}
        )

        // 空状态
        DayEventListView(
            date: Date(),
            events: [],
            themeColors: .light,
            onEventTap: { _ in },
            onManageEvents: {}
        )
    }
}
