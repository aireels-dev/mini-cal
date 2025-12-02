//
//  SystemCalendarRow.swift
//  MiniCal
//
//  系统日历行视图组件（支持行内颜色编辑）
//

import SwiftUI
import EventKit

struct SystemCalendarRow: View {
    let calendar: EKCalendar
    @Binding var isEnabled: Bool
    let themeColors: ThemeColors
    let permissionManager: PermissionManager  // 新增：PermissionManager引用
    let eventCount: Int  // 事件数
    let onToggle: () -> Void
    let onColorUpdate: (EventColor) -> Void  // 新增：颜色更新回调

    @State private var isHovered = false
    @State private var isEditingColor = false
    @State private var editColor: EventColor = .blue

    // 计算显示颜色
    private var displayColor: NSColor {
        permissionManager.getDisplayColor(for: calendar)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isEditingColor {
                // 颜色编辑模式
                colorEditingView
            } else {
                // 正常显示模式
                normalView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered && !isEditingColor ? themeColors.backgroundColor.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            if !isEditingColor {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
    }

    // MARK: - Normal View

    private var normalView: some View {
        HStack(spacing: 12) {
            // 日历颜色指示器（可点击编辑）
            Button(action: {
                startEditingColor()
            }) {
                Circle()
                    .fill(Color(displayColor))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(isHovered ? themeColors.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help("点击编辑颜色")

            // 日历标题
            VStack(alignment: .leading, spacing: 2) {
                Text(calendar.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeColors.textColor)

                HStack(spacing: 8) {
                    // 日历来源
                    if let source = calendar.source?.title {
                        Text(localizedSourceName(source))
                            .font(.system(size: 11))
                            .foregroundColor(themeColors.secondaryTextColor)
                    }

                    // 事件数量
                    if eventCount > 0 {
                        Text(String(format: NSLocalizedString("system_calendar.event_count", comment: ""), eventCount))
                            .font(.system(size: 11))
                            .foregroundColor(themeColors.secondaryTextColor)
                    }
                }
            }

            Spacer()

            // 启用/禁用开关
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .tint(themeColors.accentColor)
                .labelsHidden()
                .onChange(of: isEnabled) { oldValue, newValue in
                    if oldValue != newValue {
                        onToggle()
                    }
                }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    // MARK: - Color Editing View

    private var colorEditingView: some View {
        VStack(spacing: 8) {
            // 颜色选择
            HStack(spacing: 8) {
                Text("common.color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeColors.secondaryTextColor)
                    .frame(width: 40, alignment: .leading)

                // 颜色选择器（横向排列）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventColor.allCases, id: \.self) { color in
                            Button(action: {
                                editColor = color
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(color.swiftUIColor)
                                        .frame(width: 24, height: 24)

                                    if color == editColor {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // 操作按钮
            HStack(spacing: 8) {
                Spacer()

                Button("取消") {
                    cancelEditingColor()
                }
                .font(.system(size: 12))
                .keyboardShortcut(.escape)

                Button("保存") {
                    saveColorChanges()
                }
                .font(.system(size: 12, weight: .medium))
                .keyboardShortcut(.return)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(themeColors.accentColor.opacity(0.05))
        .cornerRadius(6)
    }

    // MARK: - Editing Actions

    private func startEditingColor() {
        // 从当前显示颜色查找最接近的 EventColor
        editColor = findClosestEventColor(from: displayColor)
        isEditingColor = true
    }

    private func cancelEditingColor() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingColor = false
        }
    }

    private func saveColorChanges() {
        onColorUpdate(editColor)
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingColor = false
        }
    }

    /// 从 NSColor 查找最接近的 EventColor
    private func findClosestEventColor(from nsColor: NSColor) -> EventColor {
        let color = Color(nsColor)

        // 尝试匹配系统预设颜色
        for eventColor in EventColor.allCases {
            if eventColor.swiftUIColor == color {
                return eventColor
            }
        }

        // 如果没有精确匹配，返回默认蓝色
        return .blue
    }

    /// 本地化日历源名称
    private func localizedSourceName(_ source: String) -> String {
        switch source {
        case "Subscribed Calendars":
            return NSLocalizedString("calendar_source.subscribed", comment: "")
        case "iCloud":
            return "iCloud"
        case "Other":
            return NSLocalizedString("calendar_source.other", comment: "")
        case "Default":
            return NSLocalizedString("calendar_source.default", comment: "")
        case "Birthdays":
            return NSLocalizedString("calendar_source.birthdays", comment: "")
        default:
            return source
        }
    }
}

#Preview {
    let calendar = EKCalendar(for: .event, eventStore: EKEventStore())
    calendar.title = "工作日历"
    calendar.color = NSColor.blue

    return SystemCalendarRow(
        calendar: calendar,
        isEnabled: .constant(true),
        themeColors: .light,
        permissionManager: PermissionManager.shared,
        eventCount: 15,
        onToggle: {},
        onColorUpdate: { _ in }
    )
    .padding()
}
