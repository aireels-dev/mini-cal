import Foundation
import Combine
import UserNotifications

class SyncStatusMonitor: ObservableObject {
    @Published var overallSyncStatus: OverallSyncStatus = .idle
    @Published var activeSyncOperations: [SyncOperation] = []
    @Published var recentSyncResults: [SyncResult] = []
    @Published var syncMetrics = SyncMetrics()

    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = UNUserNotificationCenter.current()
    private var syncTimer: Timer?

    // 配置参数
    private let maxRecentResults = 50
    private let maxActiveOperations = 3
    private let syncRetryInterval: TimeInterval = 300 // 5分钟
    private let maxRetryAttempts = 3

    init() {
        setupNotifications()
        setupPeriodicSync()
        loadSyncHistory()
    }

    deinit {
        syncTimer?.invalidate()
    }

    // MARK: - Sync Operation Management
    func startSyncOperation(subscription: CalendarSubscription, operationType: SyncOperationType) -> SyncOperation {
        let operation = SyncOperation(
            id: UUID(),
            subscriptionId: subscription.id,
            subscriptionTitle: subscription.title,
            operationType: operationType,
            startTime: Date(),
            status: .running
        )

        // 检查是否超过最大并发数
        if activeSyncOperations.count >= maxActiveOperations {
            // 将操作加入队列
            queueSyncOperation(operation)
        } else {
            // 立即开始操作
            executeSyncOperation(operation)
        }

        return operation
    }

    func updateSyncOperation(_ operation: SyncOperation, with result: SyncResult) {
        var updatedOperation = operation
        updatedOperation.endTime = Date()
        updatedOperation.status = result.isSuccess ? .completed : .failed
        updatedOperation.error = result.error
        updatedOperation.eventsProcessed = result.eventsAdded + result.eventsUpdated + result.eventsDeleted
        updatedOperation.duration = result.duration

        // 更新活跃操作列表
        if let index = activeSyncOperations.firstIndex(where: { $0.id == operation.id }) {
            activeSyncOperations[index] = updatedOperation

            // 如果操作完成，从活跃列表中移除
            if updatedOperation.status == .completed || updatedOperation.status == .failed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.activeSyncOperations.removeAll { $0.id == operation.id }
                    self.processNextQueuedOperation()
                }
            }
        }

        // 添加到最近结果
        addToRecentResults(result)

        // 更新指标
        updateSyncMetrics(with: updatedOperation)

        // 发送通知
        handleSyncCompletion(updatedOperation)
    }

    func cancelSyncOperation(_ operationId: UUID) {
        if let index = activeSyncOperations.firstIndex(where: { $0.id == operationId }) {
            var operation = activeSyncOperations[index]
            operation.status = .cancelled
            operation.endTime = Date()

            activeSyncOperations[index] = operation

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.activeSyncOperations.removeAll { $0.id == operationId }
                self.processNextQueuedOperation()
            }
        }
    }

    // MARK: - Sync Queue Management
    private var queuedOperations: [SyncOperation] = []

    private func queueSyncOperation(_ operation: SyncOperation) {
        var queuedOperation = operation
        queuedOperation.status = .queued
        queuedOperations.append(queuedOperation)
    }

    private func processNextQueuedOperation() {
        guard !queuedOperations.isEmpty,
              activeSyncOperations.count < maxActiveOperations else { return }

        let nextOperation = queuedOperations.removeFirst()
        executeSyncOperation(nextOperation)
    }

    private func executeSyncOperation(_ operation: SyncOperation) {
        var executingOperation = operation
        executingOperation.status = .running

        activeSyncOperations.append(executingOperation)

        // 更新整体状态
        updateOverallSyncStatus()
    }

    // MARK: - Sync Status Updates
    private func updateOverallSyncStatus() {
        if activeSyncOperations.isEmpty {
            overallSyncStatus = .idle
        } else if activeSyncOperations.contains(where: { $0.status == .failed }) {
            overallSyncStatus = .error
        } else {
            overallSyncStatus = .syncing
        }
    }

    // MARK: - Metrics and History
    private func updateSyncMetrics(with operation: SyncOperation) {
        if operation.status == .completed {
            syncMetrics.successfulSyncs += 1
        } else if operation.status == .failed {
            syncMetrics.failedSyncs += 1
        }

        syncMetrics.totalSyncs += 1
        syncMetrics.totalEventsProcessed += operation.eventsProcessed

        // 计算平均同步时间
        if syncMetrics.averageSyncDuration == 0 {
            syncMetrics.averageSyncDuration = operation.duration
        } else {
            syncMetrics.averageSyncDuration = (syncMetrics.averageSyncDuration + operation.duration) / 2
        }

        // 计算成功率
        syncMetrics.successRate = Double(syncMetrics.successfulSyncs) / Double(syncMetrics.totalSyncs)

        saveSyncHistory()
    }

    private func addToRecentResults(_ result: SyncResult) {
        recentSyncResults.insert(result, at: 0)

        if recentSyncResults.count > maxRecentResults {
            recentSyncResults.removeLast()
        }
    }

    // MARK: - Notifications
    private func setupNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    private func handleSyncCompletion(_ operation: SyncOperation) {
        switch operation.status {
        case .completed:
            if operation.eventsProcessed > 0 {
                sendNotification(
                    title: "同步完成",
                    body: "\(operation.subscriptionTitle) 已同步 \(operation.eventsProcessed) 个事件"
                )
            }
        case .failed:
            sendNotification(
                title: "同步失败",
                body: "\(operation.subscriptionTitle) 同步失败"
            )
        default:
            break
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    // MARK: - Periodic Sync
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncRetryInterval, repeats: true) { _ in
            self.checkForFailedSyncs()
        }
    }

    private func checkForFailedSyncs() {
        let failedOperations = recentSyncResults.filter { !$0.isSuccess }

        for result in failedOperations {
            let subscriptionId = result.subscriptionId
            checkRetryForSubscription(subscriptionId, failureCount: 1)
        }
    }

    private func checkRetryForSubscription(_ subscriptionId: UUID, failureCount: Int) {
        guard failureCount < maxRetryAttempts else { return }

        // 检查是否已经重试过
        let recentFailures = recentSyncResults.prefix(10).filter {
            $0.subscriptionId == subscriptionId && !$0.isSuccess
        }

        if recentFailures.count >= failureCount {
            // 触发重试
            NotificationCenter.default.post(
                name: .syncRetryRequested,
                object: subscriptionId
            )
        }
    }

    // MARK: - Data Persistence
    private func loadSyncHistory() {
        if let data = UserDefaults.standard.data(forKey: "SyncMetrics"),
           let metrics = try? JSONDecoder().decode(SyncMetrics.self, from: data) {
            syncMetrics = metrics
        }
    }

    private func saveSyncHistory() {
        if let data = try? JSONEncoder().encode(syncMetrics) {
            UserDefaults.standard.set(data, forKey: "SyncMetrics")
        }
    }

    // MARK: - Public Interface
    func getSyncHistory(for subscriptionId: UUID, limit: Int = 10) -> [SyncResult] {
        return recentSyncResults
            .filter { $0.subscriptionId == subscriptionId }
            .prefix(limit)
            .map { $0 }
    }

    func getSyncStatusForSubscription(_ subscriptionId: UUID) -> SyncOperationStatus? {
        return activeSyncOperations
            .first { $0.subscriptionId == subscriptionId }?
            .status
    }

    func resetMetrics() {
        syncMetrics = SyncMetrics()
        recentSyncResults.removeAll()
        saveSyncHistory()
    }
}

// MARK: - Supporting Types
enum OverallSyncStatus {
    case idle
    case syncing
    case error

    var displayName: String {
        switch self {
        case .idle: return "空闲"
        case .syncing: return "同步中"
        case .error: return "同步错误"
        }
    }
}

enum SyncOperationType: String, Codable {
    case incremental = "incremental"
    case full = "full"
    case manual = "manual"
    case scheduled = "scheduled"

    var displayName: String {
        switch self {
        case .incremental: return "增量同步"
        case .full: return "全量同步"
        case .manual: return "手动同步"
        case .scheduled: return "计划同步"
        }
    }
}

enum SyncOperationStatus: String, Codable {
    case queued = "queued"
    case running = "running"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .queued: return "排队中"
        case .running: return "同步中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        }
    }
}

struct SyncOperation: Identifiable, Codable {
    let id: UUID
    let subscriptionId: UUID
    let subscriptionTitle: String
    let operationType: SyncOperationType
    let startTime: Date
    var endTime: Date?
    var status: SyncOperationStatus
    var eventsProcessed: Int = 0
    var duration: TimeInterval = 0

    // Error不能直接Codable，所以需要自定义编码/解码
    private var errorMessage: String?

    // Custom initializer
    init(id: UUID, subscriptionId: UUID, subscriptionTitle: String, operationType: SyncOperationType, startTime: Date, status: SyncOperationStatus) {
        self.id = id
        self.subscriptionId = subscriptionId
        self.subscriptionTitle = subscriptionTitle
        self.operationType = operationType
        self.startTime = startTime
        self.status = status
    }

    // Computed property for error access
    var error: Error? {
        get {
            guard let message = errorMessage else { return nil }
            return NSError(domain: "SyncError", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        set {
            errorMessage = newValue?.localizedDescription
        }
    }

    var progress: Double {
        switch status {
        case .queued: return 0.0
        case .running: return 0.5
        case .completed, .failed, .cancelled: return 1.0
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, subscriptionId, subscriptionTitle, operationType
        case startTime, endTime, status, eventsProcessed, duration, errorMessage
    }
}

struct SyncMetrics: Codable {
    var totalSyncs: Int = 0
    var successfulSyncs: Int = 0
    var failedSyncs: Int = 0
    var totalEventsProcessed: Int = 0
    var averageSyncDuration: TimeInterval = 0
    var successRate: Double = 0

    var lastSyncDate: Date {
        // 这里应该从实际的同步历史中获取
        return Date()
    }

    var uptimePercentage: Double {
        guard totalSyncs > 0 else { return 0 }
        return successRate * 100
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let syncRetryRequested = Notification.Name("SyncRetryRequested")
    static let syncOperationCompleted = Notification.Name("SyncOperationCompleted")
    static let syncStatusChanged = Notification.Name("SyncStatusChanged")
}