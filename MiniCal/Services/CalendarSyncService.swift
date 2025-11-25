import Foundation
import EventKit
import Combine
import AppKit

/// 系统日历同步服务 - 协调EventKit和增量同步服务
/// 职责：
/// 1. 监听 EKEventStoreChanged 通知实现实时同步
/// 2. 实现定时轮询机制（默认5分钟）
/// 3. 响应应用激活事件触发同步
/// 4. 管理自动同步和手动刷新
class CalendarSyncService: ObservableObject {
    // MARK: - Dependencies
    private let eventStore: EKEventStore
    private let systemCalendarService: SystemCalendarService
    private let incrementalSyncService: IncrementalSyncService
    private let permissionManager: PermissionManager
    private let storageManager: LocalStorageManager

    // MARK: - Published State
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var error: Error?

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private var syncInterval: TimeInterval = 5 * 60 // 默认5分钟
    private var autoSyncEnabled = true

    // MARK: - Initialization
    init(
        eventStore: EKEventStore = EKEventStore(),
        systemCalendarService: SystemCalendarService = SystemCalendarService(),
        incrementalSyncService: IncrementalSyncService = IncrementalSyncService(),
        permissionManager: PermissionManager = PermissionManager(),
        storageManager: LocalStorageManager = LocalStorageManager()
    ) {
        self.eventStore = eventStore
        self.systemCalendarService = systemCalendarService
        self.incrementalSyncService = incrementalSyncService
        self.permissionManager = permissionManager
        self.storageManager = storageManager

        setupSync()
    }

    // MARK: - Sync Setup
    private func setupSync() {
        // 1. 监听 EventKit 变更通知（实时同步）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(eventStoreDidChange),
            name: .EKEventStoreChanged,
            object: eventStore
        )

        // 2. 监听应用激活通知
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncOnAppActivation()
            }
            .store(in: &cancellables)

        // 3. 启动定时轮询
        startAutoSync()

        // 4. 加载用户配置的同步间隔
        loadSyncSettings()
    }

    // MARK: - EventKit Notification Handling
    @objc private func eventStoreDidChange(_ notification: Notification) {
        // EventKit 通知：系统日历有变更，立即触发增量同步
        Task { @MainActor in
            await performIncrementalSync(reason: "EventKit 通知")
        }
    }

    // MARK: - Auto Sync Management
    private func startAutoSync() {
        guard autoSyncEnabled else { return }

        stopAutoSync() // 先停止现有timer

        syncTimer = Timer.scheduledTimer(
            withTimeInterval: syncInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.performScheduledSync()
            }
        }

        // 确保timer在RunLoop中正确调度
        RunLoop.main.add(syncTimer!, forMode: .common)
    }

    private func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Sync Triggers

    /// 应用激活时同步
    private func syncOnAppActivation() {
        guard autoSyncEnabled else { return }

        // 检查是否需要同步（距离上次同步超过间隔时间）
        if shouldPerformSync() {
            Task { @MainActor in
                await performIncrementalSync(reason: "应用激活")
            }
        }
    }

    /// 定时调度同步
    private func performScheduledSync() async {
        guard autoSyncEnabled, shouldPerformSync() else { return }

        await performIncrementalSync(reason: "定时调度")
    }

    /// 手动触发同步
    func manualSync() async {
        await performIncrementalSync(reason: "手动触发")
    }

    /// 执行增量同步
    private func performIncrementalSync(reason: String) async {
        // 防止重复同步
        guard !isSyncing else {
            print("⚠️ 同步已在进行中，跳过本次请求（原因：\(reason)）")
            return
        }

        guard permissionManager.isAuthorized else {
            print("❌ 未授权访问日历，跳过同步")
            return
        }

        print("🔄 开始同步系统日历（原因：\(reason)）")

        // 更新状态
        await MainActor.run {
            isSyncing = true
            syncProgress = 0.0
            error = nil
        }

        do {
            // 1. 获取所有系统日历订阅
            let systemSubscriptions = try await getSystemCalendarSubscriptions()

            guard !systemSubscriptions.isEmpty else {
                print("ℹ️ 没有找到系统日历订阅")
                await finishSync(success: true)
                return
            }

            print("📋 找到 \(systemSubscriptions.count) 个系统日历订阅")

            // 2. 执行批量增量同步
            await MainActor.run { syncProgress = 0.2 }

            let results = try await performBatchSync(systemSubscriptions)

            await MainActor.run { syncProgress = 0.8 }

            // 3. 处理同步结果
            processSyncResults(results)

            await MainActor.run { syncProgress = 1.0 }

            // 4. 更新最后同步时间
            await updateLastSyncDate()

            print("✅ 同步完成：\(results.count) 个订阅已同步")
            await finishSync(success: true)

        } catch {
            print("❌ 同步失败：\(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            await finishSync(success: false)
        }
    }

    // MARK: - Sync Execution
    private func getSystemCalendarSubscriptions() async throws -> [CalendarSubscription] {
        // 从存储中获取所有系统日历订阅（subscriptionType == .system）
        let allSubscriptions = storageManager.loadSubscriptions()
        return allSubscriptions.filter { $0.subscriptionType == .system && $0.isActive }
    }

    private func performBatchSync(_ subscriptions: [CalendarSubscription]) async throws -> [SyncResult] {
        var results: [SyncResult] = []

        for subscription in subscriptions {
            do {
                let result = try await performSyncForSubscription(subscription)
                results.append(result)
            } catch {
                // 单个订阅失败不影响其他订阅
                print("⚠️ 订阅 \(subscription.title) 同步失败：\(error.localizedDescription)")
                results.append(SyncResult(
                    subscriptionId: subscription.id,
                    eventsAdded: 0,
                    eventsUpdated: 0,
                    eventsDeleted: 0,
                    duration: 0,
                    error: error
                ))
            }
        }

        return results
    }

    private func performSyncForSubscription(_ subscription: CalendarSubscription) async throws -> SyncResult {
        return try await withCheckedThrowingContinuation { continuation in
            incrementalSyncService.performIncrementalSync(for: subscription)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { result in
                        continuation.resume(returning: result)
                    }
                )
                .store(in: &cancellables)
        }
    }

    private func processSyncResults(_ results: [SyncResult]) {
        let totalAdded = results.reduce(0) { $0 + $1.eventsAdded }
        let totalUpdated = results.reduce(0) { $0 + $1.eventsUpdated }
        let totalDeleted = results.reduce(0) { $0 + $1.eventsDeleted }
        let failures = results.filter { $0.error != nil }.count

        print("""
        📊 同步统计：
           - 新增事件：\(totalAdded)
           - 更新事件：\(totalUpdated)
           - 删除事件：\(totalDeleted)
           - 失败订阅：\(failures)
        """)
    }

    private func finishSync(success: Bool) async {
        await MainActor.run {
            isSyncing = false
            if success {
                syncProgress = 0.0
            }
        }
    }

    private func updateLastSyncDate() async {
        await MainActor.run {
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "LastSystemCalendarSyncDate")
        }
    }

    // MARK: - Sync Decision Logic
    private func shouldPerformSync() -> Bool {
        guard let lastSync = lastSyncDate else {
            return true // 从未同步过
        }

        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync >= syncInterval
    }

    // MARK: - Settings Management
    func updateSyncInterval(_ interval: TimeInterval) {
        syncInterval = max(60, interval) // 最小1分钟
        UserDefaults.standard.set(syncInterval, forKey: "CalendarSyncInterval")

        // 重启定时器
        if autoSyncEnabled {
            startAutoSync()
        }
    }

    func setAutoSyncEnabled(_ enabled: Bool) {
        autoSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "AutoSyncEnabled")

        if enabled {
            startAutoSync()
        } else {
            stopAutoSync()
        }
    }

    private func loadSyncSettings() {
        // 加载同步间隔（默认5分钟）
        if UserDefaults.standard.object(forKey: "CalendarSyncInterval") != nil {
            syncInterval = UserDefaults.standard.double(forKey: "CalendarSyncInterval")
        }

        // 加载自动同步开关（默认开启）
        autoSyncEnabled = UserDefaults.standard.object(forKey: "AutoSyncEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "AutoSyncEnabled")

        // 加载最后同步时间
        lastSyncDate = UserDefaults.standard.object(forKey: "LastSystemCalendarSyncDate") as? Date
    }

    // MARK: - Sync Status
    func getSyncStatus() -> CalendarSyncStatus {
        if isSyncing {
            return CalendarSyncStatus(
                state: .syncing,
                lastSyncDate: lastSyncDate,
                nextSyncDate: nil,
                progress: syncProgress,
                error: nil
            )
        }

        if let error = error {
            return CalendarSyncStatus(
                state: .failed,
                lastSyncDate: lastSyncDate,
                nextSyncDate: nextScheduledSyncDate(),
                progress: 0,
                error: error
            )
        }

        return CalendarSyncStatus(
            state: .synced,
            lastSyncDate: lastSyncDate,
            nextSyncDate: nextScheduledSyncDate(),
            progress: 0,
            error: nil
        )
    }

    private func nextScheduledSyncDate() -> Date? {
        guard autoSyncEnabled, let lastSync = lastSyncDate else {
            return nil
        }

        return lastSync.addingTimeInterval(syncInterval)
    }

    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopAutoSync()
    }
}

// MARK: - Supporting Types
struct CalendarSyncStatus {
    enum State {
        case synced
        case syncing
        case failed
        case stale
    }

    let state: State
    let lastSyncDate: Date?
    let nextSyncDate: Date?
    let progress: Double
    let error: Error?

    var statusDescription: String {
        switch state {
        case .synced:
            if let lastSync = lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                return "已同步 - \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            }
            return "已同步"
        case .syncing:
            return "同步中... \(Int(progress * 100))%"
        case .failed:
            return "同步失败"
        case .stale:
            return "需要同步"
        }
    }
}
