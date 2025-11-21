import Foundation
import EventKit
import Combine

class IncrementalSyncService: ObservableObject {
    private let eventKitService: EventKitService
    private let storageManager: LocalStorageManager
    private let permissionManager: PermissionManager

    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var errorMessage: String?

    // 同步状态追踪
    private var lastSyncDates: [UUID: Date] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(eventKitService: EventKitService = EventKitService(),
         storageManager: LocalStorageManager = LocalStorageManager(),
         permissionManager: PermissionManager = PermissionManager()) {
        self.eventKitService = eventKitService
        self.storageManager = storageManager
        self.permissionManager = permissionManager

        loadLastSyncDates()
    }

    // MARK: - Sync Management
    func performIncrementalSync(for subscription: CalendarSubscription) -> AnyPublisher<SyncResult, Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
        }

        guard let calendarId = subscription.calendarIdentifier else {
            return Fail(error: CalendarError.calendarNotFound)
                .eraseToAnyPublisher()
        }

        let startTime = Date()
        isSyncing = true
        syncProgress = 0.0
        errorMessage = nil

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SyncError.serviceUnavailable))
                return
            }

            let lastSyncDate = self.lastSyncDates[subscription.id] ?? Date.distantPast
            let syncRange = DateRange(
                startDate: lastSyncDate,
                endDate: Date()
            )

            // 更新进度
            DispatchQueue.main.async {
                self.syncProgress = 0.2
            }

            // 执行增量同步
            self.eventKitService.getEvents(in: syncRange, from: [calendarId])
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            DispatchQueue.main.async {
                                self.isSyncing = false
                                self.errorMessage = "增量同步失败: \(error.localizedDescription)"
                                promise(.failure(error))
                            }
                        }
                    },
                    receiveValue: { events in
                        DispatchQueue.main.async {
                            self.syncProgress = 0.8

                            // 处理同步结果
                            let result = self.processSyncResult(
                                subscription: subscription,
                                events: events,
                                startTime: startTime
                            )

                            // 更新最后同步时间
                            self.lastSyncDates[subscription.id] = Date()
                            self.saveLastSyncDates()

                            self.isSyncing = false
                            self.syncProgress = 1.0
                            promise(.success(result))
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }

    func performFullSync(for subscription: CalendarSubscription) -> AnyPublisher<SyncResult, Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
        }

        guard let calendarId = subscription.calendarIdentifier else {
            return Fail(error: CalendarError.calendarNotFound)
                .eraseToAnyPublisher()
        }

        let startTime = Date()
        isSyncing = true
        syncProgress = 0.0
        errorMessage = nil

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(SyncError.serviceUnavailable))
                return
            }

            // 执行过去一年的全量同步
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            let endDate = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()

            let fullSyncRange = DateRange(startDate: startDate, endDate: endDate)

            DispatchQueue.main.async {
                self.syncProgress = 0.3
            }

            self.eventKitService.getEvents(in: fullSyncRange, from: [calendarId])
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            DispatchQueue.main.async {
                                self.isSyncing = false
                                self.errorMessage = "全量同步失败: \(error.localizedDescription)"
                                promise(.failure(error))
                            }
                        }
                    },
                    receiveValue: { events in
                        DispatchQueue.main.async {
                            self.syncProgress = 0.9

                            let result = self.processSyncResult(
                                subscription: subscription,
                                events: events,
                                startTime: startTime,
                                isFullSync: true
                            )

                            // 更新最后同步时间
                            self.lastSyncDates[subscription.id] = Date()
                            self.saveLastSyncDates()

                            self.isSyncing = false
                            self.syncProgress = 1.0
                            promise(.success(result))
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Batch Sync Operations
    func syncAllSubscriptions(_ subscriptions: [CalendarSubscription]) -> AnyPublisher<[SyncResult], Error> {
        let activeSubscriptions = subscriptions.filter { $0.isActive }

        guard !activeSubscriptions.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        isSyncing = true
        syncProgress = 0.0
        errorMessage = nil

        let totalSubscriptions = activeSubscriptions.count
        var completedCount = 0

        return Publishers.MergeMany(activeSubscriptions.map { subscription in
            self.performIncrementalSync(for: subscription)
                .handleEvents(
                    receiveOutput: { _ in
                        DispatchQueue.main.async {
                            completedCount += 1
                            self.syncProgress = Double(completedCount) / Double(totalSubscriptions)
                        }
                    }
                )
        })
        .collect()
        .handleEvents(
            receiveCompletion: { completion in
                DispatchQueue.main.async {
                    self.isSyncing = false
                    if case .failure(let error) = completion {
                        self.errorMessage = "批量同步失败: \(error.localizedDescription)"
                    }
                }
            }
        )
        .eraseToAnyPublisher()
    }

    // MARK: - Sync Result Processing
    private func processSyncResult(
        subscription: CalendarSubscription,
        events: [CalendarEvent],
        startTime: Date,
        isFullSync: Bool = false
    ) -> SyncResult {
        // 这里应该实现实际的事件对比和更新逻辑
        // 简化实现，假设所有事件都是新添加的
        let eventsAdded = events.count
        let eventsUpdated = 0
        let eventsDeleted = 0
        let duration = Date().timeIntervalSince(startTime)

        // 在实际实现中，这里需要：
        // 1. 对比已有事件，识别新增、更新、删除的事件
        // 2. 更新本地存储的事件数据
        // 3. 处理事件冲突和重复

        return SyncResult(
            subscriptionId: subscription.id,
            eventsAdded: eventsAdded,
            eventsUpdated: eventsUpdated,
            eventsDeleted: eventsDeleted,
            duration: duration,
            error: nil
        )
    }

    // MARK: - Sync State Management
    private func loadLastSyncDates() {
        // 从UserDefaults加载最后同步时间
        if let data = UserDefaults.standard.data(forKey: "LastSyncDates"),
           let dates = try? JSONDecoder().decode([UUID: Date].self, from: data) {
            lastSyncDates = dates
        }
    }

    private func saveLastSyncDates() {
        if let data = try? JSONEncoder().encode(lastSyncDates) {
            UserDefaults.standard.set(data, forKey: "LastSyncDates")
        }
    }

    // MARK: - Sync Status
    func needsSync(for subscription: CalendarSubscription) -> Bool {
        guard subscription.isActive else { return false }

        let lastSync = lastSyncDates[subscription.id] ?? Date.distantPast
        let syncInterval: TimeInterval = 5 * 60 // 5分钟

        return Date().timeIntervalSince(lastSync) > syncInterval
    }

    func getSubscriptionsNeedingSync(from subscriptions: [CalendarSubscription]) -> [CalendarSubscription] {
        return subscriptions.filter { needsSync(for: $0) }
    }

    // MARK: - Sync Statistics
    func getSyncStatistics(for subscription: CalendarSubscription) -> SyncStatistics? {
        guard let lastSync = lastSyncDates[subscription.id] else {
            return nil
        }

        return SyncStatistics(
            lastSyncDate: lastSync,
            syncCount: subscription.syncStatus.syncCount,
            successRate: subscription.syncStatus.successRate,
            consecutiveFailures: subscription.syncStatus.consecutiveFailures,
            needsSync: needsSync(for: subscription)
        )
    }
}

// MARK: - Supporting Types
enum SyncError: LocalizedError {
    case serviceUnavailable
    case invalidSubscription
    case synchronizationFailed

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "同步服务不可用"
        case .invalidSubscription:
            return "无效的订阅源"
        case .synchronizationFailed:
            return "同步失败"
        }
    }
}

struct SyncStatistics {
    let lastSyncDate: Date
    let syncCount: Int
    let successRate: Double
    let consecutiveFailures: Int
    let needsSync: Bool

    var timeSinceLastSync: TimeInterval {
        Date().timeIntervalSince(lastSyncDate)
    }

    var lastSyncDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: lastSyncDate, relativeTo: Date())
    }
}