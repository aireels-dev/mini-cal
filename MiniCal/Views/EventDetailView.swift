//
//  EventDetailView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct EventDetailView: View {
    let date: CalendarDate
    let themeColors: ThemeColors
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text(dateText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeColors.textColor)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeColors.secondaryTextColor)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider()
                .background(themeColors.borderColor)

            // 事件列表
            if date.events.isEmpty {
                Text("今天没有事件")
                    .font(.system(size: 14))
                    .foregroundColor(themeColors.secondaryTextColor)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(date.events) { event in
                            EventRow(event: event, themeColors: themeColors)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(16)
        .frame(width: 300)
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

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date.gregorianDate)
    }
}

struct EventRow: View {
    let event: DateEvent
    let themeColors: ThemeColors

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 事件颜色指示器
            Circle()
                .fill(event.color.swiftUIColor)
                .frame(width: 8, height: 8)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeColors.textColor)

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(themeColors.secondaryTextColor)
                        .lineLimit(2)
                }

                // 事件类型标签
                HStack(spacing: 6) {
                    Text(eventTypeText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(event.color.swiftUIColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(event.color.swiftUIColor.opacity(0.2))
                        .cornerRadius(4)

                    if event.source == .eventKit {
                        Text("日历")
                            .font(.system(size: 10))
                            .foregroundColor(themeColors.secondaryTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeColors.secondaryTextColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(themeColors.backgroundColor.opacity(0.5))
        .cornerRadius(8)
    }

    private var eventTypeText: String {
        switch event.type {
        case .publicHoliday:
            return "假期"
        case .festival:
            return "节日"
        case .meeting:
            return "会议"
        case .birthday:
            return "生日"
        case .custom:
            return "自定义"
        }
    }
}

#Preview {
    let testDate = CalendarDate(date: Date(), isCurrentMonth: true)

    EventDetailView(
        date: testDate,
        themeColors: .light,
        onClose: {}
    )
}
