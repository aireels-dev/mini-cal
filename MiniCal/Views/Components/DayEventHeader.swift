//
//  DayEventHeader.swift
//  MiniCal
//
//  日期事件列表头部组件
//

import SwiftUI

struct DayEventHeader: View {
    let date: Date
    let themeColors: ThemeColors

    var body: some View {
        HStack(spacing: 12) {
            // 日期信息
            VStack(alignment: .leading, spacing: 2) {
                // 主日期显示（月日 + 星期）
                HStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeColors.textColor)

                    Text(weekdayText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColors.secondaryTextColor)
                }

                // 相对时间显示
                Text(relativeTimeText)
                    .font(.system(size: 12))
                    .foregroundColor(themeColors.secondaryTextColor.opacity(0.8))
            }

            Spacer()

            // 周数信息（右上角）
            VStack(alignment: .trailing, spacing: 2) {
                Text("第 \(weekOfYear) 周")
                    .font(.system(size: 11))
                    .foregroundColor(themeColors.secondaryTextColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeColors.backgroundColor.opacity(0.3))
    }

    // MARK: - Computed Properties

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var relativeTimeText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInTomorrow(date) {
            return "明天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }

    private var weekOfYear: Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        DayEventHeader(date: Date(), themeColors: .light)
        DayEventHeader(date: Date().addingTimeInterval(86400), themeColors: .light)
        DayEventHeader(date: Date().addingTimeInterval(-86400), themeColors: .light)
    }
    .frame(width: 350)
}
