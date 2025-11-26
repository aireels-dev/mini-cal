//
//  DayEventHeader.swift
//  MiniCal
//
//  日期事件列表头部组件
//

import SwiftUI
import CoreLocation

struct DayEventHeader: View {
    let date: Date
    let themeColors: ThemeColors
    let calendarSize: CalendarSize

    @StateObject private var locationService = LocationService.shared

    var body: some View {
        VStack(spacing: 8) {
            // 第一行：整合日期信息（日期 + 星期 + 相对时间）+ 周数
            HStack(spacing: 12) {
                // 左侧：日期信息整合为单行
                HStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.system(size: calendarSize.eventListTitleFontSize + 4, weight: .semibold))
                        .foregroundColor(themeColors.textColor)

                    Text(weekdayText)
                        .font(.system(size: calendarSize.eventListTitleFontSize, weight: .medium))
                        .foregroundColor(themeColors.secondaryTextColor)

                    Text("·")
                        .font(.system(size: calendarSize.eventListTitleFontSize))
                        .foregroundColor(themeColors.secondaryTextColor.opacity(0.5))

                    Text(relativeTimeText)
                        .font(.system(size: calendarSize.eventListTitleFontSize, weight: .medium))
                        .foregroundColor(themeColors.secondaryTextColor.opacity(0.8))
                }

                Spacer()

                // 右侧：周数信息
                Text("第 \(weekOfYear) 周")
                    .font(.system(size: calendarSize.eventListSubtitleFontSize))
                    .foregroundColor(themeColors.secondaryTextColor.opacity(0.7))
            }

            // 第二行：天文信息（月相 + 日出日落）
            astronomyInfoView
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

    // MARK: - Astronomy Info View

    @ViewBuilder
    private var astronomyInfoView: some View {
        HStack(spacing: 12) {
            // 月相信息（始终显示）
            moonPhaseView

            // 分隔符
            Divider()
                .frame(height: 20)

            // 日出日落信息（包含位置权限申请按钮）
            sunTimesView
        }
        .font(.system(size: calendarSize.eventListSubtitleFontSize))
        .foregroundColor(themeColors.secondaryTextColor)
    }

    private var moonPhaseView: some View {
        let phase = MoonPhaseService.shared.getMoonPhase(for: date)
        return HStack(spacing: 4) {
            Text(phase.emoji)
                .font(.system(size: calendarSize.eventListTitleFontSize))
            Text(phase.rawValue)
                .font(.system(size: calendarSize.eventListSubtitleFontSize, weight: .medium))
        }
    }

    @ViewBuilder
    private var sunTimesView: some View {
        if !locationService.locationAuthorized {
            // 未授权位置 - 显示申请按钮
            Button(action: {
                locationService.requestAuthorization()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "location.slash")
                        .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                    Text("启用位置，显示日出日落信息")
                        .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        } else if let location = locationService.currentLocation,
                  let sunTimes = SunTimeService.shared.calculate(for: date, location: location) {
            // 有位置且计算成功 - 显示日出日落
            HStack(spacing: 8) {
                // 日出
                HStack(spacing: 2) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                        .foregroundColor(.orange)
                    Text(formatTime(sunTimes.sunrise))
                        .font(.system(size: calendarSize.eventListSubtitleFontSize, weight: .medium))
                }

                // 日落
                HStack(spacing: 2) {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                        .foregroundColor(.purple)
                    Text(formatTime(sunTimes.sunset))
                        .font(.system(size: calendarSize.eventListSubtitleFontSize, weight: .medium))
                }
            }
        } else if locationService.locationAuthorized && locationService.currentLocation == nil {
            // 有权限但位置获取中
            HStack(spacing: 3) {
                Image(systemName: "location.circle")
                    .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
                Text("获取位置中...")
                    .font(.system(size: calendarSize.eventListSubtitleFontSize - 1))
            }
            .foregroundColor(themeColors.secondaryTextColor)
        }
        // 其他情况（计算失败）不显示任何内容
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        DayEventHeader(date: Date(), themeColors: .light, calendarSize: .standard)
        DayEventHeader(date: Date().addingTimeInterval(86400), themeColors: .light, calendarSize: .standard)
        DayEventHeader(date: Date().addingTimeInterval(-86400), themeColors: .light, calendarSize: .standard)
    }
    .frame(width: 350)
}
