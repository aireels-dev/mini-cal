import Foundation
import Combine
import SwiftUI

class SubscriptionManagerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var subscriptions: [CalendarSubscription] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var hasErrors = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let subscriptionService: CalendarSubscriptionService
    private let externalCalendarService: ExternalCalendarService
    private let eventService: CalendarEventService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State

    private var subscriptionsToEdit: Set<UUID> = []
    private var subscriptionsToDelete: Set<UUID> = []

    init(subscriptionService: CalendarSubscriptionService = CalendarSubscriptionService(),
         externalCalendarService: ExternalCalendarService = ExternalCalendarService(),
         eventService: CalendarEventService = CalendarEventService()) {
        self.subscriptionService = subscriptionService
        self.externalCalendarService = externalCalendarService
        self.eventService = eventService

        setupObservers()
    }

    // MARK: - Public Methods

    func loadSubscriptions() {
        isLoading = true
        hasErrors = false
        errorMessage = nil

        Task { @MainActor in
            do {
                let fetchedSubscriptions = try await subscriptionService.getAllSubscriptions()
                var externalSubscriptions = fetchedSubscriptions.filter { $0.subscriptionType == .external }

                // 加载每个订阅的事件数
                for index in externalSubscriptions.indices {
                    let subscription = externalSubscriptions[index]

                    // 获取该订阅的事件数（使用一个大的日期范围）
                    let calendar = Calendar.current
                    let now = Date()
                    let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
                    let endDate = calendar.date(byAdding: .year, value: 2, to: now) ?? now

                    do {
                        let events: [CalendarEvent] = try await withCheckedThrowingContinuation { continuation in
                            var cancellable: AnyCancellable?
                            cancellable = eventService.getEvents(
                                in: DateRange(startDate: startDate, endDate: endDate),
                                from: [subscription.id]
                            )
                            .sink(
                                receiveCompletion: { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure(let error):
                                        continuation.resume(throwing: error)
                                    }
                                    cancellable?.cancel()
                                },
                                receiveValue: { value in
                                    continuation.resume(returning: value)
                                    cancellable?.cancel()
                                }
                            )
                        }

                        externalSubscriptions[index].eventCount = events.count
                    } catch {
                        Logger.warning("Failed to load event count for subscription \(subscription.title): \(error)", category: Logger.calendar)
                        // 继续处理其他订阅，不中断整个加载流程
                    }
                }

                subscriptions = externalSubscriptions
                isLoading = false
            } catch {
                handleError(error)
                isLoading = false
            }
        }
    }

    func addSubscription(urlString: String) async throws {
        do {
            // 添加订阅
            let newSubscription = try await externalCalendarService.addSubscription(urlString: urlString)

            // 保存到本地
            try await subscriptionService.addSubscription(newSubscription)

            // 更新UI
            await MainActor.run {
                subscriptions.append(newSubscription)
            }

            Logger.info("Successfully added subscription: \(newSubscription.title)", category: Logger.calendar)

        } catch {
            Logger.error("Failed to add subscription: \(error)", category: Logger.calendar)
            throw error
        }
    }

    func toggleSubscription(_ subscriptionId: UUID) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            return
        }

        var subscription = subscriptions[index]
        subscription.isEnabled.toggle()

        await MainActor.run {
            subscriptions[index] = subscription
        }

        do {
            try await subscriptionService.updateSubscription(subscription)
            Logger.info("Toggled subscription \(subscription.title) enabled: \(subscription.isEnabled)", category: Logger.calendar)
        } catch {
            // 回滚更改
            await MainActor.run {
                subscription.isEnabled.toggle()
                subscriptions[index] = subscription
            }
            handleError(error)
        }
    }

    func refreshSubscription(_ subscriptionId: UUID) async {
        guard let subscription = subscriptions.first(where: { $0.id == subscriptionId }) else {
            return
        }

        await MainActor.run {
            updateSubscriptionStatus(subscriptionId, status: .syncing)
        }

        do {
            let events = try await externalCalendarService.syncSubscription(subscription)

            await MainActor.run {
                updateSubscriptionStatus(subscriptionId, status: .success, eventCount: events.count)
            }

            Logger.info("Successfully refreshed subscription: \(subscription.title)", category: Logger.calendar)

        } catch {
            await MainActor.run {
                updateSubscriptionStatus(subscriptionId, status: .failed)
            }
            handleError(error)
        }
    }

    func refreshAllSubscriptions() async {
        isRefreshing = true
        hasErrors = false

        // 重置所有订阅状态
        for index in subscriptions.indices {
            subscriptions[index].syncStatus.state = .syncing
        }

        let externalSubscriptions = subscriptions.filter { $0.subscriptionType == .external }

        let results = await externalCalendarService.syncMultipleSubscriptions(externalSubscriptions)

        await MainActor.run {
            for (subscriptionId, result) in results {
                switch result {
                case .success(let events):
                    updateSubscriptionStatus(subscriptionId, status: .success, eventCount: events.count)
                case .failure(let error):
                    updateSubscriptionStatus(subscriptionId, status: .failed)
                    hasErrors = true
                    Logger.error("Failed to sync subscription \(subscriptionId): \(error)", category: Logger.calendar)
                }
            }
            isRefreshing = false
        }
    }

    func confirmDelete(_ subscription: CalendarSubscription) {
        subscriptionsToDelete.insert(subscription.id)

        // 这里可以显示确认对话框
        // 为了简化，直接执行删除
        Task {
            await deleteSubscription(subscription.id)
        }
    }

    func deleteSubscription(_ subscriptionId: UUID) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            return
        }

        let subscription = subscriptions[index]

        do {
            try await subscriptionService.removeSubscription(subscriptionId)

            await MainActor.run {
                subscriptions.remove(at: index)
                subscriptionsToDelete.remove(subscriptionId)
            }

            Logger.info("Successfully deleted subscription: \(subscription.title)", category: Logger.calendar)

        } catch {
            handleError(error)
            await MainActor.run {
                subscriptionsToDelete.remove(subscriptionId)
            }
        }
    }

    func updateSubscription(_ subscription: CalendarSubscription) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
            return
        }

        do {
            try await subscriptionService.updateSubscription(subscription)

            await MainActor.run {
                subscriptions[index] = subscription
            }

            Logger.info("Successfully updated subscription: \(subscription.title)", category: Logger.calendar)

        } catch {
            handleError(error)
        }
    }

    // MARK: - Helper Methods

    private func updateSubscriptionStatus(_ subscriptionId: UUID, status: SyncStatus.SyncState, eventCount: Int? = nil) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            return
        }

        subscriptions[index].syncStatus.state = status
        if status == .success {
            subscriptions[index].lastSyncDate = Date()
            if let count = eventCount {
                subscriptions[index].eventCount = count
            }
        }
    }

    private func setupObservers() {
        // 监听订阅服务的变化
        // 这里可以添加更复杂的观察逻辑
    }

    private func handleError(_ error: Error) {
        hasErrors = true
        errorMessage = error.localizedDescription

        Logger.error("Subscription manager error: \(error)", category: Logger.calendar)

        // 发送通知给UI层
        NotificationCenter.default.post(
            name: .subscriptionManagerError,
            object: error
        )
    }

    // MARK: - Utility Methods

    func getSubscriptionURL(_ subscription: CalendarSubscription) -> String {
        return subscription.url?.absoluteString ?? ""
    }

    func getFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    func getSyncStatusText(_ status: SyncStatus) -> String {
        switch status.state {
        case .idle:
            return "未同步"
        case .syncing:
            return "同步中..."
        case .success:
            return "同步完成"
        case .failed:
            return "同步失败"
        case .disabled:
            return "已禁用"
        case .rateLimited:
            return "请求限流"
        }
    }

    func getSyncStatusColor(_ status: SyncStatus) -> Color {
        switch status.state {
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

    // MARK: - Statistics

    var totalSubscriptions: Int {
        return subscriptions.count
    }

    var enabledSubscriptions: Int {
        return subscriptions.filter { $0.isEnabled }.count
    }

    var totalEvents: Int {
        return subscriptions.reduce(0) { $0 + $1.eventCount }
    }

    var successfullySyncedSubscriptions: Int {
        return subscriptions.filter { $0.syncStatus.state == .success }.count
    }

    var failedSubscriptions: Int {
        return subscriptions.filter { $0.syncStatus.state == .failed }.count
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionManagerError = Notification.Name("SubscriptionManagerError")
    static let subscriptionAdded = Notification.Name("SubscriptionAdded")
    static let subscriptionDeleted = Notification.Name("SubscriptionDeleted")
    static let subscriptionUpdated = Notification.Name("SubscriptionUpdated")
    static let openSubscriptionManagement = Notification.Name("OpenSubscriptionManagement")
}