//
//  AutoSyncService.swift
//  MiniCal
//
//  自动同步服务 - 管理外部订阅的自动同步（应用启动 + 定时同步）
//

import Foundation
import Combine

/// 自动同步服务
class AutoSyncService: ObservableObject {
    static let shared = AutoSyncService()

    // MARK: - Configuration

    /// 同步间隔：24小时
    private let syncInterval: TimeInterval = 24 * 60 * 60

    /// 最小同步间隔：1小时（防止频繁同步）
    private let minimumSyncInterval: TimeInterval = 60 * 60

    // MARK: - Dependencies

    private let subscriptionService: CalendarSubscriptionService
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?

    // MARK: - Published Properties

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    // MARK: - Private Properties

    private let lastSyncDateKey = "AutoSync_LastSyncDate"
    private let autoSyncEnabledKey = "AutoSync_Enabled"

    var isAutoSyncEnabled: Bool {
        get {
            userDefaults.object(forKey: autoSyncEnabledKey) as? Bool ?? true
        }
        set {
            userDefaults.set(newValue, forKey: autoSyncEnabledKey)

            if newValue {
                startPeriodicSync()
            } else {
                stopPeriodicSync()
            }
        }
    }

    // MARK: - Init

    init(subscriptionService: CalendarSubscriptionService = CalendarSubscriptionService()) {
        self.subscriptionService = subscriptionService

        // 加载最后同步时间
        if let lastSync = userDefaults.object(forKey: lastSyncDateKey) as? Date {
            self.lastSyncDate = lastSync
        }

        Logger.info("AutoSyncService initialized, last sync: \(lastSyncDate?.description ?? "never")", category: Logger.calendar)
    }

    // MARK: - Public Methods

    /// 启动自动同步（应用启动时调用）
    func startAutoSync() {
        guard isAutoSyncEnabled else {
            Logger.info("Auto sync is disabled", category: Logger.calendar)
            return
        }

        Logger.info("Starting auto sync service...", category: Logger.calendar)

        // 检查是否需要立即同步
        if shouldSyncNow() {
            Logger.info("Performing initial sync on app launch", category: Logger.calendar)
            performSync()
        } else {
            Logger.info("Skipping initial sync (last sync was recent)", category: Logger.calendar)
        }

        // 启动定时同步
        startPeriodicSync()
    }

    /// 停止自动同步
    func stopAutoSync() {
        Logger.info("Stopping auto sync service", category: Logger.calendar)
        stopPeriodicSync()
    }

    /// 手动触发同步
    func syncNow() {
        Logger.info("Manual sync requested", category: Logger.calendar)
        performSync()
    }

    // MARK: - Private Methods

    /// 判断是否需要立即同步
    private func shouldSyncNow() -> Bool {
        guard let lastSync = lastSyncDate else {
            // 从未同步过
            return true
        }

        let timeSinceLastSync = Date().timeIntervalSince(lastSync)

        // 如果距离上次同步超过最小间隔，则需要同步
        return timeSinceLastSync >= minimumSyncInterval
    }

    /// 启动定时同步
    private func startPeriodicSync() {
        // 停止现有定时器
        stopPeriodicSync()

        Logger.info("Starting periodic sync timer (interval: \(Int(syncInterval / 3600))h)", category: Logger.calendar)

        // 创建新的定时器
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.performSync()
        }
    }

    /// 停止定时同步
    private func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    /// 执行同步
    private func performSync() {
        guard !isSyncing else {
            Logger.warning("Sync already in progress, skipping", category: Logger.calendar)
            return
        }

        isSyncing = true
        syncError = nil

        let syncStartTime = Date()
        Logger.info("🔄 Starting automatic subscription sync...", category: Logger.calendar)

        Task { @MainActor in
            do {
                // 获取所有订阅
                let subscriptions = try await subscriptionService.getAllSubscriptions()

                // 过滤外部订阅
                let externalSubscriptions = subscriptions.filter { $0.subscriptionType == .external && $0.isEnabled }

                if externalSubscriptions.isEmpty {
                    Logger.info("No external subscriptions to sync", category: Logger.calendar)
                    self.isSyncing = false
                    return
                }

                Logger.info("Found \(externalSubscriptions.count) external subscriptions to sync", category: Logger.calendar)

                // 并发同步所有外部订阅
                await withTaskGroup(of: (UUID, Result<Void, Error>).self) { group in
                    for subscription in externalSubscriptions {
                        group.addTask {
                            do {
                                _ = try await self.syncSubscription(subscription)
                                return (subscription.id, .success(()))
                            } catch {
                                Logger.error("Failed to sync subscription \(subscription.title): \(error)", category: Logger.calendar)
                                return (subscription.id, .failure(error))
                            }
                        }
                    }

                    var successCount = 0
                    var failureCount = 0

                    for await (_, result) in group {
                        switch result {
                        case .success:
                            successCount += 1
                        case .failure:
                            failureCount += 1
                        }
                    }

                    let duration = Date().timeIntervalSince(syncStartTime)
                    Logger.info("""
                        ✅ Auto sync completed in \(String(format: "%.2f", duration))s
                        - Success: \(successCount)
                        - Failures: \(failureCount)
                        """, category: Logger.calendar)
                }

                // 更新最后同步时间
                self.lastSyncDate = Date()
                self.userDefaults.set(self.lastSyncDate, forKey: self.lastSyncDateKey)

                // 发送同步完成通知
                NotificationCenter.default.post(name: .autoSyncCompleted, object: nil)

                self.isSyncing = false

            } catch {
                Logger.error("Auto sync failed: \(error)", category: Logger.calendar)
                self.syncError = error
                self.isSyncing = false
            }
        }
    }

    /// 同步单个订阅
    private func syncSubscription(_ subscription: CalendarSubscription) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            subscriptionService.syncSubscription(id: subscription.id)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { result in
                        if let error = result.error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Sync Status

    /// 获取距离上次同步的时间间隔描述
    func getTimeSinceLastSync() -> String {
        guard let lastSync = lastSyncDate else {
            return "从未同步"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.context.effectiveInterfaceLocale.rawValue)
        formatter.unitsStyle = .full

        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }

    /// 获取下次同步的时间
    func getNextSyncTime() -> Date? {
        guard let lastSync = lastSyncDate else {
            return nil
        }

        return lastSync.addingTimeInterval(syncInterval)
    }

    /// 获取下次同步的时间描述
    func getTimeUntilNextSync() -> String {
        guard let nextSync = getNextSyncTime() else {
            return "未知"
        }

        if nextSync <= Date() {
            return "即将同步"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.context.effectiveInterfaceLocale.rawValue)
        formatter.unitsStyle = .full

        return formatter.localizedString(for: nextSync, relativeTo: Date())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let autoSyncCompleted = Notification.Name("autoSyncCompleted")
}
