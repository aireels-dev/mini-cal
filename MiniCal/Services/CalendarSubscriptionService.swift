import Foundation
import Combine
import EventKit

class CalendarSubscriptionService: CalendarSubscriptionServiceProtocol {
    private let storageManager: LocalStorageManager
    private let systemCalendarService: SystemCalendarService
    private let permissionManager: PermissionManager
    private let externalCalendarService: ExternalCalendarService
    private let externalEventStorage: ExternalEventStorage
    private var cancellables = Set<AnyCancellable>()

    @Published var subscriptions: [CalendarSubscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(storageManager: LocalStorageManager = LocalStorageManager(),
         systemCalendarService: SystemCalendarService = SystemCalendarService(),
         permissionManager: PermissionManager = PermissionManager(),
         externalCalendarService: ExternalCalendarService = ExternalCalendarService(),
         externalEventStorage: ExternalEventStorage = ExternalEventStorage.shared) {
        self.storageManager = storageManager
        self.systemCalendarService = systemCalendarService
        self.permissionManager = permissionManager
        self.externalCalendarService = externalCalendarService
        self.externalEventStorage = externalEventStorage

        loadSubscriptions()
        setupBindings()
    }

    // MARK: - Setup
    private func setupBindings() {
        storageManager.$subscriptions
            .receive(on: DispatchQueue.main)
            .assign(to: \.subscriptions, on: self)
            .store(in: &cancellables)
    }

    private func loadSubscriptions() {
        subscriptions = storageManager.loadSubscriptions()
    }

    // MARK: - CalendarSubscriptionServiceProtocol Implementation
    func getAllSubscriptions() -> AnyPublisher<[CalendarSubscription], Error> {
        return Just(subscriptions)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getSubscription(id: UUID) -> AnyPublisher<CalendarSubscription?, Error> {
        return Just(subscriptions.first { $0.id == id })
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func addSubscription(_ subscription: CalendarSubscription) -> AnyPublisher<CalendarSubscription, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SubscriptionError.serviceUnavailable))
                return
            }

            // 检查重复
            if self.subscriptions.contains(where: { $0.id == subscription.id }) {
                promise(.failure(SubscriptionError.duplicate))
                return
            }

            // 检查系统日历有效性
            if subscription.subscriptionType == .system {
                guard let identifier = subscription.calendarIdentifier,
                      let _ = self.systemCalendarService.getCalendarInfo(for: identifier) else {
                    promise(.failure(SubscriptionError.invalidSystemCalendar))
                    return
                }
            }

            var newSubscription = subscription
            newSubscription.updatedAt = Date()

            self.storageManager.addSubscription(newSubscription)
            promise(.success(newSubscription))
        }
        .eraseToAnyPublisher()
    }

    func updateSubscription(_ subscription: CalendarSubscription) -> AnyPublisher<CalendarSubscription, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SubscriptionError.serviceUnavailable))
                return
            }

            guard self.subscriptions.contains(where: { $0.id == subscription.id }) else {
                promise(.failure(SubscriptionError.notFound))
                return
            }

            var updatedSubscription = subscription
            updatedSubscription.updatedAt = Date()

            self.storageManager.updateSubscription(updatedSubscription)
            promise(.success(updatedSubscription))
        }
        .eraseToAnyPublisher()
    }

    func deleteSubscription(id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SubscriptionError.serviceUnavailable))
                return
            }

            guard self.subscriptions.contains(where: { $0.id == id }) else {
                promise(.failure(SubscriptionError.notFound))
                return
            }

            self.storageManager.deleteSubscription(id: id)
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    // MARK: - External Subscriptions
    func validateSubscriptionURL(_ url: URL) -> AnyPublisher<URLValidationResult, Error> {
        return Future { promise in
            // 简化的URL验证 - 实际实现会进行网络请求
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                let isValid = self.isValidCalendarURL(url)
                let result = URLValidationResult(
                    isValid: isValid,
                    calendarType: isValid ? .ical : nil,
                    title: isValid ? "外部日历" : nil,
                    estimatedEventCount: isValid ? Int.random(in: 10...100) : nil,
                    error: isValid ? nil : .invalidURL
                )
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }

    func addExternalSubscription(url: URL, title: String) -> AnyPublisher<CalendarSubscription, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SubscriptionError.serviceUnavailable))
                return
            }

            let subscription = CalendarSubscription(
                title: title,
                color: .blue,
                subscriptionType: .external
            )

            var newSubscription = subscription
            newSubscription.url = url

            self.addSubscription(newSubscription)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { subscription in
                        promise(.success(subscription))
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Sync Management
    func syncSubscription(id: UUID) -> AnyPublisher<SyncResult, Error> {
        return Future { [weak self] promise in
            guard let self = self,
                  let subscription = self.subscriptions.first(where: { $0.id == id }) else {
                promise(.failure(SubscriptionError.notFound))
                return
            }

            let startTime = Date()

            // 根据订阅类型选择不同的同步策略
            switch subscription.subscriptionType {
            case .external:
                // 外部订阅：实际下载并解析事件
                Task {
                    do {
                        Logger.info("🔄 Starting external subscription sync for: \(subscription.title)", category: Logger.calendar)

                        let events = try await self.externalCalendarService.syncSubscription(subscription)

                        // 将事件标记为属于该订阅
                        let taggedEvents = events.map { event in
                            var taggedEvent = event
                            taggedEvent.subscriptionId = subscription.id
                            return taggedEvent
                        }

                        // 持久化事件到外部事件存储
                        await MainActor.run {
                            self.externalEventStorage.saveEvents(taggedEvents, for: subscription.id)
                        }

                        let duration = Date().timeIntervalSince(startTime)
                        let result = SyncResult(
                            subscriptionId: id,
                            eventsAdded: events.count,
                            eventsUpdated: 0,
                            eventsDeleted: 0,
                            duration: duration,
                            error: nil
                        )

                        // 更新同步状态
                        var updatedSubscription = subscription
                        updatedSubscription.syncStatus.recordSuccess()
                        updatedSubscription.lastSyncDate = Date()

                        await MainActor.run {
                            self.storageManager.updateSubscription(updatedSubscription)
                        }

                        Logger.info("✅ External subscription sync completed: \(events.count) events", category: Logger.calendar)

                        // 发送事件更新通知
                        NotificationCenter.default.post(name: .subscriptionUpdated, object: nil)

                        promise(.success(result))

                    } catch {
                        Logger.error("❌ External subscription sync failed: \(error)", category: Logger.calendar)

                        // 记录同步失败
                        var updatedSubscription = subscription
                        updatedSubscription.syncStatus.recordFailure(error.localizedDescription)

                        await MainActor.run {
                            self.storageManager.updateSubscription(updatedSubscription)
                        }

                        let duration = Date().timeIntervalSince(startTime)
                        let result = SyncResult(
                            subscriptionId: id,
                            eventsAdded: 0,
                            eventsUpdated: 0,
                            eventsDeleted: 0,
                            duration: duration,
                            error: error
                        )
                        promise(.success(result))
                    }
                }

            case .system:
                // 系统日历：由 EventService 自动处理，无需额外同步
                let result = SyncResult(
                    subscriptionId: id,
                    eventsAdded: 0,
                    eventsUpdated: 0,
                    eventsDeleted: 0,
                    duration: 0,
                    error: nil
                )

                var updatedSubscription = subscription
                updatedSubscription.lastSyncDate = Date()
                self.storageManager.updateSubscription(updatedSubscription)

                Logger.info("ℹ️ System calendar sync skipped (handled by EventService)", category: Logger.calendar)
                promise(.success(result))

            case .local:
                // 本地事件：由 CalendarEventService 管理，无需同步
                let result = SyncResult(
                    subscriptionId: id,
                    eventsAdded: 0,
                    eventsUpdated: 0,
                    eventsDeleted: 0,
                    duration: 0,
                    error: nil
                )

                var updatedSubscription = subscription
                updatedSubscription.lastSyncDate = Date()
                self.storageManager.updateSubscription(updatedSubscription)

                Logger.info("ℹ️ Local calendar sync skipped (managed locally)", category: Logger.calendar)
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }

    func syncAllActiveSubscriptions() -> AnyPublisher<[SyncResult], Error> {
        let activeSubscriptions = subscriptions.filter { $0.isActive }
        let syncPublishers = activeSubscriptions.map { subscription in
            self.syncSubscription(id: subscription.id)
        }

        return Publishers.MergeMany(syncPublishers)
            .collect()
            .eraseToAnyPublisher()
    }

    func refreshSubscription(id: UUID) -> AnyPublisher<Void, Error> {
        return syncSubscription(id: id)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Helper Methods
    private func isValidCalendarURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https", "webcal"].contains(scheme)
    }

    // MARK: - System Calendar Integration
    func autoDetectSystemCalendars() -> AnyPublisher<[CalendarSubscription], Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
        }

        return systemCalendarService.detectSystemCalendars()
            .map { [weak self] calendars in
                guard let self = self else { return [] }
                return calendars.map { self.systemCalendarService.createSubscription(for: $0) }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Additional Methods for MenuBarController

    func requestCalendarPermissions() async -> Bool {
        return await permissionManager.requestEventKitAccess()
    }

    func refreshAllSubscriptions() async throws {
        // 简化实现，这里应该调用具体的同步逻辑
        print("Refreshing all subscriptions...")
    }

    // MARK: - Async Methods
    func addSubscription(_ subscription: CalendarSubscription) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            addSubscription(subscription)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { _ in
                        continuation.resume()
                    }
                )
                .store(in: &cancellables)
        }
    }

    func updateSubscription(_ subscription: CalendarSubscription) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            updateSubscription(subscription)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { _ in
                        continuation.resume()
                    }
                )
                .store(in: &cancellables)
        }
    }

    func removeSubscription(_ subscriptionId: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            deleteSubscription(id: subscriptionId)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }

    func getAllSubscriptions() async throws -> [CalendarSubscription] {
        return try await withCheckedThrowingContinuation { continuation in
            getAllSubscriptions()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { subscriptions in
                        continuation.resume(returning: subscriptions)
                    }
                )
                .store(in: &cancellables)
        }
    }
}

// MARK: - Error Types
enum SubscriptionError: LocalizedError {
    case serviceUnavailable
    case duplicate
    case notFound
    case invalidSystemCalendar
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "订阅服务不可用"
        case .duplicate:
            return "订阅源已存在"
        case .notFound:
            return "找不到订阅源"
        case .invalidSystemCalendar:
            return "无效的系统日历"
        case .validationFailed:
            return "订阅源验证失败"
        }
    }
}