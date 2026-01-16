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
        if #available(macOS 12.0, *) {
            contentView
                .alert("subscription.add_failed", isPresented: showSubscriptionError) {
                    Button("common.ok", role: .cancel) {
                        subscriptionError = nil
                    }
                } message: {
                    if let error = subscriptionError {
                        Text(error.localizedDescription)
                    }
                }
        } else {
            contentView
                .alert(isPresented: showSubscriptionError) {
                    let title = Text("subscription.add_failed".localized())
                    let message = Text(subscriptionError?.localizedDescription ?? "")
                    let dismiss = Alert.Button.cancel(Text("common.ok".localized())) {
                        subscriptionError = nil
                    }
                    return Alert(title: title, message: message, dismissButton: dismiss)
                }
        }
    }

    private var contentView: some View {
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
        .onAppear {
            viewModel.loadSubscriptions()
        }
    }

    private var showSubscriptionError: Binding<Bool> {
        Binding(
            get: { subscriptionError != nil },
            set: { newValue in
                if !newValue {
                    subscriptionError = nil
                }
            }
        )
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            Text("subscription.manager_title")
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
                Text("subscription.no_subscriptions")
                    .font(.headline)
                    .foregroundColor(themeColors.textColor)

                Text("subscription.add_to_view")
                    .font(.body)
                    .foregroundColor(themeColors.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                showingURLInput = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("subscription.add")
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
                    Text("subscription.add")
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
                    Text("subscription.refresh_all_button")
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

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("subscription.add_button")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("subscription.url_input_placeholder")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("subscription.calendar_url")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextField("https://calendar.example.com/calendar.ics", text: $url, onCommit: {
                        if !url.isEmpty {
                            onAdd()
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("subscription.protocol_hint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("subscription.common_services")
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
        .overlay(loadingOverlay)
    }
}

private extension URLInputView {
    var loadingOverlay: some View {
        Group {
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
