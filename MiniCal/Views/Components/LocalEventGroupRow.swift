//
//  LocalEventGroupRow.swift
//  MiniCal
//
//  本地事件组行视图（组级别管理）
//

import SwiftUI

struct LocalEventGroupRow: View {
    let themeColors: ThemeColors
    let groupConfig: LocalEventGroupConfig
    let eventCount: Int
    let onColorUpdate: (EventColor) -> Void

    @State private var isHovered = false
    @State private var isEditingColor = false
    @State private var editColor: EventColor = .blue

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
            // 组颜色指示器（可点击编辑）
            Button(action: {
                startEditingColor()
            }) {
                Circle()
                    .fill(groupConfig.color.swiftUIColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(isHovered ? themeColors.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help(Text("local_group.edit_color_hint"))

            // 组标题和事件数
            VStack(alignment: .leading, spacing: 2) {
                Text(groupConfig.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeColors.textColor)

                HStack(spacing: 8) {
                    // 事件数量
                    if eventCount > 0 {
                        Text(String(format: NSLocalizedString("local_group.event_count", comment: ""), eventCount))
                            .font(.system(size: 11))
                            .foregroundColor(themeColors.secondaryTextColor)
                    } else {
                        Text("calendar.no_events")
                            .font(.system(size: 11))
                            .foregroundColor(themeColors.secondaryTextColor.opacity(0.6))
                    }
                }
            }

            Spacer()

            // 启用状态（始终启用，仅显示）
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(themeColors.accentColor)
                .font(.system(size: 16))
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

                Button("common.cancel") {
                    cancelEditingColor()
                }
                .font(.system(size: 12))
                .keyboardShortcut(.escape)

                Button("common.save") {
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
        editColor = groupConfig.color
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
}

#Preview {
    VStack(spacing: 8) {
        LocalEventGroupRow(
            themeColors: .light,
            groupConfig: .default,
            eventCount: 15,
            onColorUpdate: { _ in }
        )

        LocalEventGroupRow(
            themeColors: .light,
            groupConfig: .default,
            eventCount: 0,
            onColorUpdate: { _ in }
        )
    }
    .padding()
    .frame(width: 500)
}
