import SwiftUI

struct SubscriptionManagerView: View {
    @StateObject private var viewModel = SubscriptionManagerViewModel()
    @State private var showingAddSubscription = false
    @State private var showingURLInput = false
    @State private var inputURL = ""
    @State private var isLoadingSubscription = false
    @State private var subscriptionError: Error?

    let themeColors: ThemeColors

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            headerView

            Divider()
                .background(themeColors.borderColor)

            // 订阅列表
            subscriptionListView

            // 底部操作区
            bottomActionsView
        }
        .frame(width: 450, height: 500)
        .background(themeColors.backgroundColor)
        .sheet(isPresented: $showingURLInput) {
            URLInputView(
                url: $inputURL,
                isLoading: $isLoadingSubscription,
                error: $subscriptionError,
                onAdd: {
                    addSubscription()
                },
                onCancel: {
                    showingURLInput = false
                    inputURL = ""
                    subscriptionError = nil
                }
            )
        }
        .alert("添加订阅失败", isPresented: .constant(subscriptionError != nil)) {
            Button("确定") {
                subscriptionError = nil
            }
        } message: {
            if let error = subscriptionError {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.loadSubscriptions()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Text("日历订阅管理")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeColors.textColor)

            Spacer()

            // 同步状态指示器
            HStack(spacing: 8) {
                statusIndicator

                Button(action: {
                    Task {
                        await viewModel.refreshAllSubscriptions()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(themeColors.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help("刷新所有订阅")
                .disabled(viewModel.isRefreshing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var statusIndicator: some View {
        Group {
            if viewModel.isRefreshing {
                ProgressView()
                    .scaleEffect(0.7)
            } else if viewModel.hasErrors {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12))
            }
        }
    }

    // MARK: - Subscription List View

    private var subscriptionListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.subscriptions.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.subscriptions) { subscription in
                        SubscriptionRowView(
                            subscription: subscription,
                            themeColors: themeColors,
                            onToggle: {
                                Task {
                                    await viewModel.toggleSubscription(subscription.id)
                                }
                            },
                            onDelete: {
                                viewModel.confirmDelete(subscription)
                            },
                            onRefresh: {
                                Task {
                                    await viewModel.refreshSubscription(subscription.id)
                                }
                            },
                            onEdit: {
                                // 编辑功能（可后续实现）
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(themeColors.secondaryTextColor)

            VStack(spacing: 8) {
                Text("还没有订阅任何日历")
                    .font(.headline)
                    .foregroundColor(themeColors.textColor)

                Text("添加外部日历订阅来查看更多事件")
                    .font(.body)
                    .foregroundColor(themeColors.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                showingURLInput = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加订阅")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(themeColors.accentColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Bottom Actions View

    private var bottomActionsView: some View {
        HStack {
            Button(action: {
                showingURLInput = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("添加订阅")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeColors.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(themeColors.accentColor.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                Task {
                    await viewModel.refreshAllSubscriptions()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("全部刷新")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeColors.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(themeColors.backgroundColor.opacity(0.5))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isRefreshing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeColors.backgroundColor.opacity(0.8))
    }

    // MARK: - Actions

    private func addSubscription() {
        guard !inputURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isLoadingSubscription = true
        subscriptionError = nil

        Task {
            do {
                try await viewModel.addSubscription(urlString: inputURL)
                await MainActor.run {
                    showingURLInput = false
                    inputURL = ""
                    isLoadingSubscription = false
                }
            } catch {
                await MainActor.run {
                    subscriptionError = error
                    isLoadingSubscription = false
                }
            }
        }
    }
}

// MARK: - URL Input View

struct URLInputView: View {
    @Binding var url: String
    @Binding var isLoading: Bool
    @Binding var error: Error?
    let onAdd: () -> Void
    let onCancel: () -> Void

    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("添加日历订阅")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("输入外部日历的URL地址")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("日历URL")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("https://calendar.example.com/calendar.ics", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isURLFieldFocused)
                        .onSubmit {
                            if !url.isEmpty {
                                onAdd()
                            }
                        }

                    Text("支持 http://、https:// 和 webcal:// 协议")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("常见日历服务")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 4) {
                        HelpItem(icon: "calendar", title: "Google Calendar", description: "在Google日历设置中获取iCal链接")
                        HelpItem(icon: "calendar", title: "Apple iCloud", description: "在iCloud日历中共享日历")
                        HelpItem(icon: "calendar", title: "Outlook", description: "在Outlook日历中导出iCal链接")
                    }
                }

                Spacer()

                HStack {
                    Button("取消") {
                        onCancel()
                    }
                    .keyboardShortcut(.escape)
                    .disabled(isLoading)

                    Spacer()

                    Button("添加") {
                        onAdd()
                    }
                    .keyboardShortcut(.return)
                    .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
            .navigationTitle("添加订阅")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onAdd()
                    }
                    .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            isURLFieldFocused = true
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

// MARK: - Help Item

struct HelpItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SubscriptionManagerView(themeColors: .light)
}