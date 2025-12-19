//
//  ExternalSubscriptionCompactRow.swift
//  MiniCal
//
//  外部订阅紧凑行视图组件（支持行内编辑）
//

import SwiftUI

struct ExternalSubscriptionCompactRow: View {
    let subscription: CalendarSubscription
    let onToggle: () -> Void
    let onUpdate: (CalendarSubscription) -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    @State private var isEditing = false
    @State private var isEditingColor = false
    @State private var editTitle: String = ""
    @State private var editColor: EventColor = .blue
    @State private var isEnabled: Bool
    @FocusState private var isTitleFieldFocused: Bool

    init(subscription: CalendarSubscription,
         onToggle: @escaping () -> Void,
         onUpdate: @escaping (CalendarSubscription) -> Void,
         onDelete: @escaping () -> Void) {
        self.subscription = subscription
        self.onToggle = onToggle
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._isEnabled = State(initialValue: subscription.isEnabled)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isEditingColor {
                // 颜色编辑模式
                colorEditingView
            } else if isEditing {
                // 编辑模式
                editingView
            } else {
                // 正常显示模式
                normalView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered && !isEditing && !isEditingColor ? Color.primary.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            if !isEditing && !isEditingColor {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .alert("subscription.confirm_delete_title", isPresented: $showingDeleteConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text(String(format: NSLocalizedString("subscription.confirm_delete_message", comment: ""), subscription.title))
        }
    }

    // MARK: - Normal View

    private var normalView: some View {
        HStack(spacing: 12) {
            // 订阅颜色指示器（可点击编辑）
            Button(action: {
                startEditingColor()
            }) {
                Circle()
                    .fill(subscription.color.swiftUIColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(isHovered ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help("点击编辑颜色")

            // 订阅标题
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // 同步状态
                    syncStatusBadge
                }
            }

            Spacer()

            // 操作按钮（悬停时显示）
            if isHovered {
                HStack(spacing: 8) {
                    // 编辑按钮
                    Button(action: {
                        startEditing()
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundColor(Color.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("编辑订阅")

                    // 删除按钮
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("删除订阅")
                }
            }

            // 启用/禁用开关
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .tint(Color.accentColor)
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

    // MARK: - Editing View

    private var editingView: some View {
        VStack(spacing: 8) {
            // 第一行：标题编辑
            HStack(spacing: 8) {
                Text("common.name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                TextField("订阅名称", text: $editTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTitleFieldFocused)
                    .font(.system(size: 13))
            }

            // 第二行：URL 显示（只读）
            HStack(spacing: 8) {
                Text("misc.url")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Text(subscription.url?.absoluteString ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 第三行：颜色选择
            HStack(spacing: 8) {
                Text("common.color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
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

            // 第四行：操作按钮
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
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(6)
    }

    // MARK: - Sync Status Badge

    private var syncStatusBadge: some View {
        HStack(spacing: 3) {
            statusIcon
            Text(statusText)
                .font(.system(size: 10))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(3)
    }

    private var statusIcon: some View {
        Group {
            switch subscription.syncStatus.state {
            case .idle:
                Image(systemName: "pause.circle")
                    .font(.system(size: 8))
            case .syncing:
                ProgressView()
                    .scaleEffect(0.5)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
            case .disabled:
                Image(systemName: "xmark.circle")
                    .font(.system(size: 8))
            case .rateLimited:
                Image(systemName: "clock")
                    .font(.system(size: 8))
            }
        }
    }

    private var statusText: String {
        return subscription.syncStatus.state.displayName
    }

    private var statusColor: Color {
        switch subscription.syncStatus.state {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        case .disabled:
            return .gray
        case .rateLimited:
            return .orange
        }
    }

    // MARK: - Color Editing View

    private var colorEditingView: some View {
        VStack(spacing: 8) {
            // 颜色选择
            HStack(spacing: 8) {
                Text("common.color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
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
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(6)
    }

    // MARK: - Editing Actions

    private func startEditingColor() {
        editColor = subscription.color
        isEditingColor = true
    }

    private func cancelEditingColor() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingColor = false
        }
    }

    private func saveColorChanges() {
        var updatedSubscription = subscription
        updatedSubscription.color = editColor

        onUpdate(updatedSubscription)

        withAnimation(.easeInOut(duration: 0.2)) {
            isEditingColor = false
        }
    }

    private func startEditing() {
        editTitle = subscription.title
        editColor = subscription.color
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
        var updatedSubscription = subscription
        updatedSubscription.title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedSubscription.color = editColor

        onUpdate(updatedSubscription)

        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
    }
}

#Preview {
    var subscription1 = CalendarSubscription(
        title: "工作日历",
        color: .blue,
        subscriptionType: .external
    )
    subscription1.eventCount = 15

    var subscription2 = CalendarSubscription(
        title: "节假日",
        color: .red,
        subscriptionType: .external
    )
    subscription2.eventCount = 8
    subscription2.syncStatus.state = .failed

    return VStack(spacing: 8) {
        ExternalSubscriptionCompactRow(
            subscription: subscription1,
            onToggle: {},
            onUpdate: { _ in },
            onDelete: {}
        )

        ExternalSubscriptionCompactRow(
            subscription: subscription2,
            onToggle: {},
            onUpdate: { _ in },
            onDelete: {}
        )
    }
    .padding()
    .frame(width: 500)
}
