# Data Model Specification: 日历事件订阅管理

**Feature**: `003-calendar-subscription` | **Date**: 2025-10-30
**Phase**: 1 - Data Model & Contract Design

## Overview

本文档定义了日历事件订阅管理功能的完整数据模型，基于MiniCal现有架构扩展，确保向后兼容性和一致的设计原则。

## Core Data Models

### 1. CalendarSubscription (日历订阅源)

代表一个日历数据源，包含系统日历和外部订阅日历。

```swift
import Foundation

struct CalendarSubscription: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var url: URL?                     // 外部订阅源的URL
    var calendarIdentifier: String?   // EventKit日历标识符
    var color: EventColor             // 分配的特征颜色
    var isActive: Bool                // 是否启用
    var subscriptionType: SubscriptionType
    var syncStatus: SyncStatus
    var lastSyncDate: Date?
    var nextSyncDate: Date?
    var errorMessage: String?
    var createdAt: Date
    var updatedAt: Date

    enum SubscriptionType: String, Codable, CaseIterable {
        case system = "system"         // 系统日历
        case external = "external"     // 外部订阅
        case local = "local"          // 本地创建
    }

    // 用于系统集成的只读属性
    var isSystemCalendar: Bool {
        subscriptionType == .system && calendarIdentifier != nil
    }

    var isExternalSubscription: Bool {
        subscriptionType == .external && url != nil
    }

    // 同步状态检查
    var needsSync: Bool {
        guard isActive else { return false }
        guard let nextSync = nextSyncDate else { return true }
        return Date() >= nextSync
    }

    // 验证订阅源有效性
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
}
```

### 2. CalendarEvent (日历事件)

扩展现有的DateEvent模型，支持EventKit集成和订阅源关联。

```swift
import Foundation

struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var location: String?
    var notes: String?
    var url: URL?
    var recurrenceRule: String?     // RRULE格式
    var attendees: [EventAttendee]?

    // 关联信息
    var subscriptionId: UUID?       // 所属订阅源
    var eventIdentifier: String?    // EventKit事件标识符
    var source: EventSource

    // 元数据
    var isCreatedLocally: Bool
    var isEditable: Bool
    var lastModified: Date?
    var sequence: Int?              // 事件版本号

    // 状态信息
    var status: EventStatus
    var visibility: EventVisibility

    enum EventStatus: String, Codable, CaseIterable {
        case confirmed = "confirmed"
        case tentative = "tentative"
        case cancelled = "cancelled"
    }

    enum EventVisibility: String, Codable, CaseIterable {
        case public = "public"
        case private = "private"
        case confidential = "confidential"
    }

    // 计算属性
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var isMultiDay: Bool {
        !Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }

    var isPastEvent: Bool {
        endDate < Date()
    }

    var isCurrentEvent: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    // 验证事件有效性
    var isValid: Bool {
        return !title.isEmpty &&
               startDate <= endDate &&
               (startDate.timeIntervalSince1970 > 0) &&
               (endDate.timeIntervalSince1970 > 0)
    }
}

// 参与者信息
struct EventAttendee: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String?
    var status: AttendeeStatus
    var isOrganizer: Bool

    enum AttendeeStatus: String, Codable, CaseIterable {
        case needsAction = "needsAction"
        case accepted = "accepted"
        case declined = "declined"
        case tentative = "tentative"
        case delegated = "delegated"
    }
}
```

### 3. SyncStatus (同步状态)

跟踪订阅源的同步状态和错误信息。

```swift
import Foundation

struct SyncStatus: Codable, Hashable {
    var state: SyncState
    var lastSyncDate: Date?
    var lastSuccessDate: Date?
    var lastErrorDate: Date?
    var lastErrorMessage: String?
    var consecutiveFailures: Int
    var syncCount: Int               // 总同步次数
    var successRate: Double          // 成功率 (0.0-1.0)

    enum SyncState: String, Codable, CaseIterable {
        case idle = "idle"           // 空闲状态
        case syncing = "syncing"     // 正在同步
        case success = "success"     // 同步成功
        case failed = "failed"       // 同步失败
        case disabled = "disabled"   // 已禁用
        case rateLimited = "rateLimited" // 频率限制
    }

    init() {
        self.state = .idle
        self.consecutiveFailures = 0
        self.syncCount = 0
        self.successRate = 1.0
    }

    // 计算属性
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

    // 状态更新方法
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

    mutating func updateSuccessRate() {
        if syncCount > 0 {
            let successCount = syncCount - consecutiveFailures
            successRate = Double(successCount) / Double(syncCount)
        }
    }
}
```

### 4. ColorScheme (颜色方案)

扩展颜色管理，支持订阅源的颜色分配和自定义。

```swift
import Foundation
import SwiftUI

struct ColorScheme: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colors: [ColorAssignment]
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    struct ColorAssignment: Codable, Hashable {
        let eventType: EventType
        let color: EventColor
        var isCustom: Bool
    }

    // 预定义颜色方案
    static let builtInSchemes: [ColorScheme] = [
        ColorScheme(
            id: UUID(),
            name: "默认配色",
            colors: EventType.allCases.map {
                ColorAssignment(eventType: $0, color: $0.defaultColor, isCustom: false)
            },
            isBuiltIn: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        ColorScheme(
            id: UUID(),
            name: "高对比度",
            colors: EventType.allCases.enumerated().map { index, type in
                let highContrastColors: [EventColor] = [.red, .blue, .green, .orange, .purple, .yellow]
                let color = highContrastColors[index % highContrastColors.count]
                return ColorAssignment(eventType: type, color: color, isCustom: false)
            },
            isBuiltIn: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]

    // 查找方法
    func color(for eventType: EventType) -> EventColor? {
        return colors.first { $0.eventType == eventType }?.color
    }

    mutating func setColor(for eventType: EventType, color: EventColor) {
        if let index = colors.firstIndex(where: { $0.eventType == eventType }) {
            colors[index] = ColorAssignment(eventType: eventType, color: color, isCustom: true)
        } else {
            colors.append(ColorAssignment(eventType: eventType, color: color, isCustom: true))
        }
        updatedAt = Date()
    }

    // 颜色冲突检测
    func hasColorConflicts() -> [ColorConflict] {
        var conflicts: [ColorConflict] = []
        let colorGroups = Dictionary(grouping: colors) { $0.color }

        for (color, assignments) in colorGroups where assignments.count > 1 {
            let conflict = ColorConflict(
                color: color,
                eventTypes: assignments.map { $0.eventType },
                severity: assignments.count > 2 ? .high : .medium
            )
            conflicts.append(conflict)
        }

        return conflicts
    }
}

struct ColorConflict: Identifiable, Codable, Hashable {
    let id = UUID()
    let color: EventColor
    let eventTypes: [EventType]
    let severity: ConflictSeverity

    enum ConflictSeverity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}
```

## Service Contracts

### 1. CalendarSubscriptionServiceProtocol

```swift
import Foundation
import Combine

protocol CalendarSubscriptionServiceProtocol {
    // 订阅源管理
    func getAllSubscriptions() -> AnyPublisher<[CalendarSubscription], Error>
    func getSubscription(id: UUID) -> AnyPublisher<CalendarSubscription?, Error>
    func addSubscription(_ subscription: CalendarSubscription) -> AnyPublisher<CalendarSubscription, Error>
    func updateSubscription(_ subscription: CalendarSubscription) -> AnyPublisher<CalendarSubscription, Error>
    func deleteSubscription(id: UUID) -> AnyPublisher<Void, Error>

    // 外部订阅
    func validateSubscriptionURL(_ url: URL) -> AnyPublisher<URLValidationResult, Error>
    func addExternalSubscription(url: URL, title: String) -> AnyPublisher<CalendarSubscription, Error>

    // 同步管理
    func syncSubscription(id: UUID) -> AnyPublisher<SyncResult, Error>
    func syncAllActiveSubscriptions() -> AnyPublisher<[SyncResult], Error>
    func refreshSubscription(id: UUID) -> AnyPublisher<Void, Error>
}

struct URLValidationResult {
    let isValid: Bool
    let calendarType: CalendarType?
    let title: String?
    let estimatedEventCount: Int?
    let error: ValidationError?

    enum CalendarType {
        case ical
        case googleCalendar
        case outlook
        case other
    }

    enum ValidationError: Error {
        case invalidURL
        case unsupportedFormat
        case networkError
        case accessDenied
    }
}

struct SyncResult {
    let subscriptionId: UUID
    let eventsAdded: Int
    let eventsUpdated: Int
    let eventsDeleted: Int
    let duration: TimeInterval
    let error: Error?

    var hasChanges: Bool {
        eventsAdded + eventsUpdated + eventsDeleted > 0
    }

    var isSuccess: Bool {
        error == nil
    }
}
```

### 2. CalendarEventServiceProtocol

```swift
import Foundation
import Combine

protocol CalendarEventServiceProtocol {
    // 事件查询
    func getEvents(for date: Date, from subscriptionIds: [UUID]?) -> AnyPublisher<[CalendarEvent], Error>
    func getEvents(in dateRange: DateRange, from subscriptionIds: [UUID]?) -> AnyPublisher<[CalendarEvent], Error>
    func getEvent(id: UUID) -> AnyPublisher<CalendarEvent?, Error>

    // 事件管理
    func createEvent(_ event: CalendarEvent) -> AnyPublisher<CalendarEvent, Error>
    func updateEvent(_ event: CalendarEvent) -> AnyPublisher<CalendarEvent, Error>
    func deleteEvent(id: UUID) -> AnyPublisher<Void, Error>

    // 事件搜索
    func searchEvents(query: String, in dateRange: DateRange?) -> AnyPublisher<[CalendarEvent], Error>
    func getEventsWithRecurrence(baseEventId: UUID) -> AnyPublisher<[CalendarEvent], Error>
}

struct DateRange {
    let startDate: Date
    let endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        guard startDate <= endDate else {
            fatalError("DateRange: startDate must be <= endDate")
        }
    }

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
}
```

### 3. ColorAssignmentServiceProtocol

```swift
import Foundation
import Combine

protocol ColorAssignmentServiceProtocol {
    // 颜色分配
    func assignColor(to subscription: CalendarSubscription, excluding existingColors: [EventColor]) -> EventColor
    func optimizeColorAssignments(for subscriptions: [CalendarSubscription]) -> [ColorConflict]

    // 颜色方案管理
    func getColorSchemes() -> AnyPublisher<[ColorScheme], Error>
    func createColorScheme(_ scheme: ColorScheme) -> AnyPublisher<ColorScheme, Error>
    func updateColorScheme(_ scheme: ColorScheme) -> AnyPublisher<ColorScheme, Error>
    func deleteColorScheme(id: UUID) -> AnyPublisher<Void, Error>

    // 颜色冲突解决
    func resolveColorConflicts(_ conflicts: [ColorConflict]) -> AnyPublisher<[ColorAssignment], Error>
    func suggestAlternativeColor(for eventType: EventType, excluding colors: [EventColor]) -> EventColor?
}
```

## Data Relationships

```mermaid
erDiagram
    CalendarSubscription ||--o{ CalendarEvent : "contains"
    CalendarSubscription }o--|| ColorScheme : "uses"
    CalendarSubscription ||--o| SyncStatus : "tracks"
    CalendarEvent }o--o| EventAttendee : "has"

    CalendarSubscription {
        UUID id PK
        String title
        URL? url
        String? calendarIdentifier
        EventColor color
        Bool isActive
        SubscriptionType subscriptionType
        SyncStatus syncStatus
        Date? lastSyncDate
        Date? nextSyncDate
        String? errorMessage
        Date createdAt
        Date updatedAt
    }

    CalendarEvent {
        UUID id PK
        String title
        Date startDate
        Date endDate
        Bool isAllDay
        String? location
        String? notes
        URL? url
        String? recurrenceRule
        UUID? subscriptionId FK
        String? eventIdentifier
        EventSource source
        Bool isCreatedLocally
        Bool isEditable
        Date? lastModified
        Int? sequence
        EventStatus status
        EventVisibility visibility
    }

    ColorScheme {
        UUID id PK
        String name
        ColorAssignment[] colors
        Bool isBuiltIn
        Date createdAt
        Date updatedAt
    }

    SyncStatus {
        SyncState state
        Date? lastSyncDate
        Date? lastSuccessDate
        Date? lastErrorDate
        String? lastErrorMessage
        Int consecutiveFailures
        Int syncCount
        Double successRate
    }

    EventAttendee {
        UUID id PK
        String name
        String? email
        AttendeeStatus status
        Bool isOrganizer
        UUID eventId FK
    }
```

## Data Validation Rules

### CalendarSubscription Validation

- **title**: 必填，长度1-100字符
- **url**: 外部订阅必填，必须是有效的HTTP/HTTPS/WebCal URL
- **calendarIdentifier**: 系统日历必填，必须是有效的EventKit标识符
- **color**: 必填，必须是预定义的EventColor值
- **subscriptionType**: 必填，必须是有效的SubscriptionType

### CalendarEvent Validation

- **title**: 必填，长度1-200字符
- **startDate**: 必填，不能为空
- **endDate**: 必填，必须>= startDate
- **subscriptionId**: 可选，但必须指向有效的订阅源
- **eventIdentifier**: EventKit事件必填

### SyncStatus Validation

- **consecutiveFailures**: 必须>= 0
- **syncCount**: 必须>= 0
- **successRate**: 必须>= 0.0 且 <= 1.0

## Migration Strategy

### Phase 1: 扩展现有模型

1. 扩展`DateEvent`模型添加订阅相关字段
2. 创建`CalendarSubscription`和`SyncStatus`模型
3. 保持向后兼容性，新字段设为可选

### Phase 2: 数据迁移

1. 现有事件自动关联到"本地"订阅源
2. 系统日历检测和自动订阅
3. 用户设置迁移到新的颜色方案系统

### Phase 3: 清理

1. 移除不再使用的旧字段
2. 统一数据访问接口
3. 性能优化和索引建立

## Performance Considerations

### Indexing Strategy

- `CalendarEvent.startDate` + `CalendarEvent.endDate`: 用于日期范围查询
- `CalendarEvent.subscriptionId`: 用于订阅源事件查询
- `CalendarSubscription.isActive`: 用于活跃订阅源过滤
- `CalendarSubscription.nextSyncDate`: 用于同步调度

### Caching Strategy

- 热点事件数据内存缓存
- 订阅源配置持久化缓存
- 颜色方案配置缓存
- 同步状态实时缓存

### Query Optimization

- 使用批量查询减少数据库访问
- 预加载关联数据避免N+1查询
- 分页加载大量事件数据
- 智能预取常用数据

---

**Data Model Design Completed**: 2025-10-30
**Ready for Phase 1 Continued**: Contract Generation