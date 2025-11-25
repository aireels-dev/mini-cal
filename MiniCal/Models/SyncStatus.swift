import Foundation

// MARK: - SyncStatus Data Model
struct SyncStatus: Codable, Hashable {
    var state: SyncState
    var lastSyncDate: Date?
    var lastSuccessDate: Date?
    var lastErrorDate: Date?
    var lastErrorMessage: String?
    var consecutiveFailures: Int
    var syncCount: Int
    var successRate: Double

    enum SyncState: String, Codable, CaseIterable {
        case idle = "idle"
        case syncing = "syncing"
        case success = "success"
        case failed = "failed"
        case disabled = "disabled"
        case rateLimited = "rateLimited"
    }

    init() {
        self.state = .idle
        self.consecutiveFailures = 0
        self.syncCount = 0
        self.successRate = 1.0
    }

    var isHealthy: Bool {
        state != .failed && consecutiveFailures < 3
    }

    var needsRetry: Bool {
        state == .failed && consecutiveFailures < 5
    }

    var timeSinceLastSync: TimeInterval? {
        guard let lastSync = lastSyncDate else { return nil }
        return Date().timeIntervalSince(lastSync)
    }

    mutating func recordSuccess() {
        state = .success
        lastSyncDate = Date()
        lastSuccessDate = Date()
        lastErrorMessage = nil
        consecutiveFailures = 0
        syncCount += 1
        updateSuccessRate()
    }

    mutating func recordFailure(_ error: String) {
        state = .failed
        lastSyncDate = Date()
        lastErrorDate = Date()
        lastErrorMessage = error
        consecutiveFailures += 1
        syncCount += 1
        updateSuccessRate()
    }

    private mutating func updateSuccessRate() {
        if syncCount > 0 {
            let successCount = syncCount - consecutiveFailures
            successRate = Double(successCount) / Double(syncCount)
        }
    }
}