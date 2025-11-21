import Foundation

// MARK: - SubscriptionType Enum
enum SubscriptionType: String, Codable, CaseIterable {
    case system = "system"
    case external = "external"
    case local = "local"
}

// MARK: - CalendarSubscription Data Model
struct CalendarSubscription: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var url: URL?
    var calendarIdentifier: String?
    var color: EventColor
    var isActive: Bool
    var subscriptionType: SubscriptionType
    var syncStatus: SyncStatus
    var lastSyncDate: Date?
    var nextSyncDate: Date?
    var errorMessage: String?
    var createdAt: Date
    var updatedAt: Date
    var eventCount: Int = 0

    var isEnabled: Bool {
        get { isActive }
        set { isActive = newValue }
    }

    var isSystemCalendar: Bool {
        subscriptionType == .system && calendarIdentifier != nil
    }

    var isExternalSubscription: Bool {
        subscriptionType == .external && url != nil
    }

    var needsSync: Bool {
        guard isActive else { return false }
        guard let nextSync = nextSyncDate else { return true }
        return Date() >= nextSync
    }

    var isValid: Bool {
        switch subscriptionType {
        case .system:
            return calendarIdentifier != nil && !calendarIdentifier!.isEmpty
        case .external:
            return url != nil && url!.scheme != nil
        case .local:
            return true
        }
    }

    init(title: String, color: EventColor, subscriptionType: SubscriptionType) {
        self.id = UUID()
        self.title = title
        self.color = color
        self.subscriptionType = subscriptionType
        self.isActive = true
        self.syncStatus = SyncStatus()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}