import SwiftUI

struct SubscriptionRowView: View {
    let subscription: CalendarSubscription
    let themeColors: ThemeColors
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onRefresh: () -> Void
    let onEdit: () -> Void

    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // 主要内容区域
            HStack(spacing: 16) {
                // 颜色指示器
                colorIndicator

                // 订阅信息
                VStack(alignment: .leading, spacing: 6) {
                    // 标题
                    HStack {
                        Text(subscription.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeColors.textColor)
                            .lineLimit(1)

                        Spacer()

                        // 同步状态
                        syncStatusIndicator
                    }

                    // URL
                    Text(subscription.url?.absoluteString ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(themeColors.secondaryTextColor)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    // 统计信息
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(themeColors.secondaryTextColor)

                            Text("\(subscription.eventCount) 个事件")
                                .font(.system(size: 11))
                                .foregroundColor(themeColors.secondaryTextColor)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(themeColors.secondaryTextColor)

                            Text(lastSyncText)
                                .font(.system(size: 11))
                                .foregroundColor(themeColors.secondaryTextColor)
                        }

                        Spacer()
                    }
                }

                // 操作按钮
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // 底部分隔线
            Divider()
                .background(themeColors.borderColor)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? themeColors.backgroundColor.opacity(0.8) : themeColors.backgroundColor.opacity(0.5))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) {
                showingDeleteConfirmation = false
            }
            Button("删除", role: .destructive) {
                onDelete()
                showingDeleteConfirmation = false
            }
        } message: {
            Text("确定要删除订阅「\(subscription.title)」吗？此操作无法撤销。")
        }
    }

    // MARK: - Color Indicator

    private var colorIndicator: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(subscription.color.swiftUIColor)
            .frame(width: 4)
            .padding(.vertical, 8)
    }

    // MARK: - Sync Status Indicator

    private var syncStatusIndicator: some View {
        HStack(spacing: 4) {
            statusIcon

            Text(statusText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.1))
        .cornerRadius(4)
    }

    private var statusIcon: some View {
        Group {
            switch subscription.syncStatus.state {
            case .idle:
                Image(systemName: "pause.circle")
                    .font(.system(size: 8))
            case .syncing:
                ProgressView()
                    .scaleEffect(0.6)
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
        switch subscription.syncStatus.state {
        case .idle:
            return "未同步"
        case .syncing:
            return "同步中"
        case .success:
            return "完成"
        case .failed:
            return "失败"
        case .disabled:
            return "已禁用"
        case .rateLimited:
            return "限流"
        }
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            // 启用/禁用开关
            Toggle("", isOn: .constant(subscription.isEnabled))
                .toggleStyle(SwitchToggleStyle(tint: themeColors.accentColor))
                .controlSize(.mini)
                .onChange(of: subscription.isEnabled) { _ in
                    onToggle()
                }

            if isHovered {
                // 刷新按钮
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(themeColors.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help("刷新订阅")
                .disabled(subscription.syncStatus.state == .syncing)

                // 编辑按钮
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(themeColors.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help("编辑订阅")

                // 删除按钮
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("删除订阅")
            }
        }
    }

    // MARK: - Computed Properties

    private var lastSyncText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        if let lastSync = subscription.lastSyncDate {
            return formatter.localizedString(for: lastSync, relativeTo: Date())
        }
        return "从未同步"
    }
}

// MARK: - Custom Toggle Style

struct SwitchToggleStyle: ToggleStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? tint : Color.gray.opacity(0.3))
                .frame(width: 32, height: 18)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .offset(x: configuration.isOn ? 7 : -7)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

#Preview {
    var subscription1 = CalendarSubscription(
        title: "工作日历",
        color: .blue,
        subscriptionType: .external
    )
    subscription1.url = URL(string: "https://calendar.google.com/calendar/ical")!
    subscription1.lastSyncDate = Date()

    var subscription2 = CalendarSubscription(
        title: "节假日日历",
        color: .red,
        subscriptionType: .external
    )
    subscription2.url = URL(string: "https://example.com/holidays.ics")!
    subscription2.isActive = false
    subscription2.syncStatus.state = .failed
    subscription2.lastSyncDate = Date().addingTimeInterval(-3600)

    return VStack(spacing: 12) {
        SubscriptionRowView(
            subscription: subscription1,
            themeColors: .light,
            onToggle: {},
            onDelete: {},
            onRefresh: {},
            onEdit: {}
        )

        SubscriptionRowView(
            subscription: subscription2,
            themeColors: .light,
            onToggle: {},
            onDelete: {},
            onRefresh: {},
            onEdit: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}