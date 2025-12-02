//
//  LocalEventGroupCompactRow.swift
//  MiniCal
//
//  本地事件组紧凑行视图组件（支持行内编辑）
//

import SwiftUI

struct LocalEventGroupCompactRow: View {
    let group: LocalEventGroupConfig
    let eventCount: Int
    let themeColors: ThemeColors
    let onUpdate: (LocalEventGroupConfig) -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    @State private var isEditingColor = false
    @State private var editTitle: String = ""
    @State private var editColor: EventColor = .blue
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isEditingColor {
                // 颜色编辑模式
                colorEditingView
            } else if isEditing {
                // 编辑模式（仅非默认组）
                editingView
            } else {
                // 正常显示模式
                normalView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered && !isEditing && !isEditingColor ? themeColors.backgroundColor.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            if !isEditing && !isEditingColor {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .alert("local_group.confirm_delete_title", isPresented: $showingDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text(String(format: NSLocalizedString("local_group.confirm_delete_message", comment: ""), group.title))
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
                    .fill(group.color.swiftUIColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(isHovered ? themeColors.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help("点击编辑颜色")

            // 组标题
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.localizedTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeColors.textColor)
                        .lineLimit(1)

                    // 默认组标记
                    if group.isDefault {
                        Text("misc.default")
                            .font(.system(size: 10))
                            .foregroundColor(themeColors.accentColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(themeColors.accentColor.opacity(0.1))
                            .cornerRadius(3)
                    }
                }

                // 事件数量（始终显示）
                Text(eventCount > 0 ? String(format: NSLocalizedString("local_group.event_count", comment: ""), eventCount) : NSLocalizedString("calendar.no_events", comment: ""))
                    .font(.system(size: 11))
                    .foregroundColor(themeColors.secondaryTextColor)
            }

            Spacer()

            // 操作按钮（悬停时显示，默认组不显示删除按钮）
            if isHovered && !group.isDefault {
                HStack(spacing: 8) {
                    // 编辑按钮
                    Button(action: {
                        startEditing()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundColor(themeColors.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("编辑类别")

                    // 删除按钮
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("删除类别")
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    // MARK: - Editing View (仅非默认组)

    private var editingView: some View {
        VStack(spacing: 8) {
            // 第一行：标题编辑
            HStack(spacing: 8) {
                Text("common.name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeColors.secondaryTextColor)
                    .frame(width: 40, alignment: .leading)

                TextField("组名称", text: $editTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTitleFieldFocused)
                    .font(.system(size: 13))
            }

            // 第二行：颜色选择
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

            // 第三行：操作按钮
            HStack(spacing: 8) {
                Spacer()

                Button("取消") {
                    cancelEditing()
                }
                .font(.system(size: 12))
                .keyboardShortcut(.escape)

                Button("保存") {
                    saveChanges()
                }
                .font(.system(size: 12, weight: .medium))
                .keyboardShortcut(.return)
                .disabled(editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(themeColors.accentColor.opacity(0.05))
        .cornerRadius(6)
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
        editColor = group.color
        isEditingColor = true
    }

    private func cancelEditingColor() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingColor = false
        }
    }

    private func saveColorChanges() {
        var updatedGroup = group
        updatedGroup.color = editColor

        onUpdate(updatedGroup)

        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingColor = false
        }
    }

    private func startEditing() {
        // 默认组不允许编辑名称
        if group.isDefault {
            return
        }

        editTitle = group.title
        editColor = group.color
        isEditing = true
        // 延迟聚焦，确保 TextField 已经渲染
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTitleFieldFocused = true
        }
    }

    private func cancelEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
        editTitle = ""
        editColor = .blue
    }

    private func saveChanges() {
        var updatedGroup = group
        updatedGroup.title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGroup.color = editColor

        onUpdate(updatedGroup)

        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
    }
}

#Preview {
    var defaultGroup = LocalEventGroupConfig.default

    var customGroup = LocalEventGroupConfig(
        id: UUID(),
        title: "工作事件",
        color: .blue,
        isEnabled: true,
        isDefault: false
    )

    return VStack(spacing: 8) {
        LocalEventGroupCompactRow(
            group: defaultGroup,
            eventCount: 5,
            themeColors: .light,
            onUpdate: { _ in },
            onDelete: {}
        )

        LocalEventGroupCompactRow(
            group: customGroup,
            eventCount: 3,
            themeColors: .light,
            onUpdate: { _ in },
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 500)
}
