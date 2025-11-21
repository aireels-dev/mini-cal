# Service Interfaces: 日历事件订阅管理

**Created**: 2025-10-30
**Feature**: 日历事件订阅管理

## Service Layer Architecture

本功能采用协议导向的设计，确保可测试性和模块化。所有服务接口都定义清晰的契约，便于单元测试和未来的扩展。

## Core Service Protocols

### 1. CalendarSubscriptionService Protocol

```swift
import Foundation
import Combine

/// 日历订阅管理服务协议
protocol CalendarSubscriptionServiceProtocol {
    // MARK: - Subscription Management

    /// 获取所有订阅源
    func getAllSubscriptions() -> AnyPublisher<[CalendarSubscription], Never>

    /// 获取启用的订阅源
    func getActiveSubscriptions() -> AnyPublisher<[CalendarSubscription], Never>

    /// 添加新订阅源
    func addSubscription(_ subscription: CalendarSubscription) async throws

    /// 更新订阅源
    func updateSubscription(_ subscription: CalendarSubscription) async throws

    /// 删除订阅源
    func deleteSubscription(id: UUID) async throws

    /// 切换订阅源启用状态
    func toggleSubscription(id: UUID) async throws

    // MARK: - System Calendar Integration

    /// 检测系统日历变化
    func detectSystemCalendars() async -> [CalendarSubscription]

    /// 添加系统日历订阅
    func addSystemCalendar(_ calendar: EKCalendar) async throws

    /// 移除系统日历订阅
    func removeSystemCalendar(id: UUID) async throws

    // MARK: - External Subscription

    /// 通过URI添加外部订阅
    func addExternalSubscription(url: URL, name: String) async throws

    /// 验证外部订阅URI
    func validateSubscriptionURL(_ url: URL) async -> ValidationResult

    // MARK: - Color Management

    /// 自动分配颜色
    func assignColorToSubscription(id: UUID) async throws

    /// 更新订阅源颜色
    func updateSubscriptionColor(id: UUID, color: Color) async throws

    // MARK: - Sync Status

    /// 获取同步状态
    func getSyncStatus(id: UUID) -> AnyPublisher<SyncStatus, Never>

    /// 手动触发同步
    func syncSubscription(id: UUID) async throws

    /// 同步所有订阅源
    func syncAllSubscriptions() async throws
}

/// 验证结果
struct ValidationResult {
    let isValid: Bool
    let error: ValidationError?
    let suggestedName: String?

    enum ValidationError {
        case invalidURL
        case unsupportedFormat
        case networkError
        case authenticationRequired
    }
}
```

### 2. CalendarEventService Protocol

```swift
/// 日历事件服务协议
protocol CalendarEventServiceProtocol {
    // MARK: - Event Retrieval

    /// 获取指定日期的所有事件
    func getEvents(for date: Date) -> AnyPublisher<[DateEvent], Error>

    /// 获取指定日期范围内的事件
    func getEvents(from startDate: Date, to endDate: Date) -> AnyPublisher<[DateEvent], Error>

    /// 获取特定订阅源的事件
    func getEvents(for subscriptionId: UUID, date: Date) -> AnyPublisher<[DateEvent], Error>

    /// 搜索事件
    func searchEvents(query: String) -> AnyPublisher<[DateEvent], Error>

    // MARK: - Event Creation & Management

    /// 创建新事件
    func createEvent(_ event: DateEvent) async throws -> DateEvent

    /// 更新事件
    func updateEvent(_ event: DateEvent) async throws

    /// 删除事件
    func deleteEvent(id: String) async throws

    /// 批量创建事件
    func createEvents(_ events: [DateEvent]) async throws -> [DateEvent]

    // MARK: - Event Templates

    /// 获取事件模板
    func getEventTemplates() -> AnyPublisher<[EventTemplate], Never>

    /// 创建事件模板
    func createEventTemplate(_ template: EventTemplate) async throws

    /// 基于模板创建事件
    func createEventFromTemplate(templateId: UUID, date: Date) async throws -> DateEvent

    // MARK: - Event Reminders

    /// 设置事件提醒
    func setReminder(for eventId: String, minutesBefore: Int) async throws

    /// 移除事件提醒
    func removeReminder(for eventId: String) async throws
}
```

### 3. CalendarSyncService Protocol

```swift
/// 日历同步服务协议
protocol CalendarSyncServiceProtocol {
    // MARK: - Sync Management

    /// 开始自动同步
    func startAutoSync()

    /// 停止自动同步
    func stopAutoSync()

    /// 检查同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Never>

    /// 手动触发同步
    func performSync() async throws

    // MARK: - Incremental Sync

    /// 增量同步指定订阅源
    func syncSubscriptionIncremental(id: UUID) async throws

    /// 全量同步指定订阅源
    func syncSubscriptionFull(id: UUID) async throws

    // MARK: - Conflict Resolution

    /// 解决同步冲突
    func resolveSyncConflict(conflict: SyncConflict) async throws

    /// 获取待解决的冲突
    func getPendingConflicts() -> AnyPublisher<[SyncConflict], Never>

    // MARK: - Offline Support

    /// 获取离线缓存状态
    func getOfflineCacheStatus() -> AnyPublisher<OfflineCacheStatus, Never>

    /// 清理离线缓存
    func clearOfflineCache() async throws

    /// 预加载离线数据
    func preloadOfflineData(for dateRange: DateRange) async throws
}

/// 同步冲突
struct SyncConflict {
    let eventId: String
    let localEvent: DateEvent
    let remoteEvent: DateEvent
    let conflictType: ConflictType

    enum ConflictType {
        case modificationConflict  // 修改冲突
        case deletionConflict     // 删除冲突
        case duplicationConflict  // 重复冲突
    }
}

/// 离线缓存状态
struct OfflineCacheStatus {
    let isCacheEnabled: Bool
    let lastSyncDate: Date?
    let cachedEventCount: Int
    let cacheSize: Int64  // 字节
    let needsSync: Bool
}
```

### 4. UserPreferencesService Protocol

```swift
/// 用户偏好设置服务协议
protocol UserPreferencesServiceProtocol {
    // MARK: - Preferences Management

    /// 获取用户偏好设置
    func getUserPreferences() -> AnyPublisher<UserPreferences, Never>

    /// 更新用户偏好设置
    func updateUserPreferences(_ preferences: UserPreferences) async throws

    /// 重置为默认设置
    func resetToDefaults() async throws

    // MARK: - Theme Management

    /// 获取可用主题
    func getAvailableThemes() -> AnyPublisher<[Theme], Never>

    /// 应用主题
    func applyTheme(_ theme: Theme) async throws

    // MARK: - Notification Settings

    /// 获取通知设置
    func getNotificationSettings() -> AnyPublisher<NotificationSettings, Never>

    /// 更新通知设置
    func updateNotificationSettings(_ settings: NotificationSettings) async throws

    // MARK: - Import/Export

    /// 导出设置
    func exportSettings() async throws -> Data

    /// 导入设置
    func importSettings(from data: Data) async throws
}

/// 通知设置
struct NotificationSettings: Codable {
    var enableNotifications: Bool
    var defaultReminderMinutes: Int
    var enableEventCreationNotification: Bool
    var enableSyncFailureNotification: Bool
    var enableConflictNotification: Bool
}
```

### 5. ColorManagementService Protocol

```swift
/// 颜色管理服务协议
protocol ColorManagementServiceProtocol {
    // MARK: - Color Palette

    /// 获取颜色调色板
    func getColorPalette() -> AnyPublisher<ColorPalette, Never>

    /// 更新颜色调色板
    func updateColorPalette(_ palette: ColorPalette) async throws

    /// 添加自定义颜色
    func addCustomColor(_ color: ColorData) async throws

    /// 删除自定义颜色
    func removeCustomColor(id: UUID) async throws

    // MARK: - Color Assignment

    /// 智能分配颜色
    func assignSmartColor(subscriptionId: UUID) async throws -> Color

    /// 获取推荐颜色
    func getRecommendedColors(excluding usedColors: [Color]) -> AnyPublisher<[Color], Never>

    /// 检查颜色对比度
    func checkColorContrast(foreground: Color, background: Color) -> Bool

    // MARK: - Color Presets

    /// 获取颜色预设
    func getColorPresets() -> AnyPublisher<[ColorPreset], Never>

    /// 应用颜色预设
    func applyColorPreset(_ preset: ColorPreset) async throws

    /// 创建颜色预设
    func createColorPreset(_ preset: ColorPreset) async throws
}

/// 颜色预设
struct ColorPreset: Identifiable, Codable {
    let id: UUID
    let name: String
    let colors: [Color]
    let isDefault: Bool
    let createdAt: Date
}
```

## Implementation Examples

### CalendarSubscriptionService Implementation

```swift
import EventKit
import Combine

class CalendarSubscriptionService: CalendarSubscriptionServiceProtocol {
    private let eventStore: EKEventStore
    private let userDefaults: UserDefaults
    private let colorService: ColorManagementServiceProtocol
    private let syncService: CalendarSyncServiceProtocol

    private var subscriptionsSubject = CurrentValueSubject<[CalendarSubscription], Never>([])
    private var cancellables = Set<AnyCancellable>()

    init(
        eventStore: EKEventStore = EKEventStore(),
        userDefaults: UserDefaults = UserDefaults.standard,
        colorService: ColorManagementServiceProtocol,
        syncService: CalendarSyncServiceProtocol
    ) {
        self.eventStore = eventStore
        self.userDefaults = userDefaults
        self.colorService = colorService
        self.syncService = syncService

        loadSubscriptions()
        setupSystemCalendarObserver()
    }

    // MARK: - Subscription Management

    func getAllSubscriptions() -> AnyPublisher<[CalendarSubscription], Never> {
        return subscriptionsSubject.eraseToAnyPublisher()
    }

    func getActiveSubscriptions() -> AnyPublisher<[CalendarSubscription], Never> {
        return subscriptionsSubject
            .map { $0.filter { $0.isActive } }
            .eraseToAnyPublisher()
    }

    func addSubscription(_ subscription: CalendarSubscription) async throws {
        var subscriptions = subscriptionsSubject.value

        // 检查重复
        guard !subscriptions.contains(where: { $0.id == subscription.id }) else {
            throw SubscriptionError.duplicateSubscription
        }

        // 如果是系统日历，验证EventKit ID
        if subscription.source == .system,
           let calendarId = subscription.eventKitCalendarId,
           eventStore.calendar(withIdentifier: calendarId) == nil {
            throw SubscriptionError.systemCalendarNotFound
        }

        subscriptions.append(subscription)
        await saveSubscriptions(subscriptions)
        subscriptionsSubject.send(subscriptions)

        // 触发初始同步
        try await syncService.syncSubscriptionFull(id: subscription.id)
    }

    func updateSubscription(_ subscription: CalendarSubscription) async throws {
        var subscriptions = subscriptionsSubject.value

        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
            throw SubscriptionError.subscriptionNotFound
        }

        subscriptions[index] = subscription
        await saveSubscriptions(subscriptions)
        subscriptionsSubject.send(subscriptions)
    }

    func deleteSubscription(id: UUID) async throws {
        var subscriptions = subscriptionsSubject.value

        guard let index = subscriptions.firstIndex(where: { $0.id == id }) else {
            throw SubscriptionError.subscriptionNotFound
        }

        let subscription = subscriptions[index]

        // 如果是系统日历，不需要删除EventKit中的日历
        // 如果是外部订阅，清理相关缓存
        if subscription.source == .external {
            await clearSubscriptionCache(subscription)
        }

        subscriptions.remove(at: index)
        await saveSubscriptions(subscriptions)
        subscriptionsSubject.send(subscriptions)
    }

    // MARK: - System Calendar Integration

    func detectSystemCalendars() async -> [CalendarSubscription] {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else {
            return []
        }

        let systemCalendars = eventStore.calendars(for: .event)
        let existingSubscriptions = subscriptionsSubject.value

        return systemCalendars.compactMap { calendar in
            // 检查是否已存在
            if existingSubscriptions.contains(where: { $0.eventKitCalendarId == calendar.calendarIdentifier }) {
                return nil
            }

            return CalendarSubscription(
                name: calendar.title,
                color: Color(calendar.cgColor),
                source: .system,
                eventKitCalendarId: calendar.calendarIdentifier
            )
        }
    }

    // MARK: - External Subscription

    func addExternalSubscription(url: URL, name: String) async throws {
        // 验证URL
        let validationResult = await validateSubscriptionURL(url)
        guard validationResult.isValid else {
            throw SubscriptionError.invalidURL(validationResult.error)
        }

        // 创建订阅
        let color = try await colorService.assignSmartColor(subscriptionId: UUID())
        let subscription = CalendarSubscription(
            name: name,
            uri: url,
            color: color,
            source: .external
        )

        try await addSubscription(subscription)
    }

    func validateSubscriptionURL(_ url: URL) async -> ValidationResult {
        do {
            let request = URLRequest(url: url)
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return ValidationResult(isValid: false, error: .networkError, suggestedName: nil)
            }

            switch httpResponse.statusCode {
            case 200...299:
                // 检查Content-Type是否支持日历格式
                if let contentType = httpResponse.mimeType,
                   contentType.contains("calendar") || contentType.contains("ical") {
                    let suggestedName = extractSuggestedName(from: url)
                    return ValidationResult(isValid: true, error: nil, suggestedName: suggestedName)
                } else {
                    return ValidationResult(isValid: false, error: .unsupportedFormat, suggestedName: nil)
                }
            case 401:
                return ValidationResult(isValid: false, error: .authenticationRequired, suggestedName: nil)
            default:
                return ValidationResult(isValid: false, error: .networkError, suggestedName: nil)
            }
        } catch {
            return ValidationResult(isValid: false, error: .networkError, suggestedName: nil)
        }
    }

    // MARK: - Private Methods

    private func loadSubscriptions() {
        let subscriptions = userDefaults.loadSubscriptions()
        subscriptionsSubject.send(subscriptions)
    }

    @MainActor
    private func saveSubscriptions(_ subscriptions: [CalendarSubscription]) {
        userDefaults.saveSubscriptions(subscriptions)
    }

    private func setupSystemCalendarObserver() {
        // 监听系统日历变化
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshSystemCalendars()
                }
            }
            .store(in: &cancellables)
    }

    private func refreshSystemCalendars() async {
        let detectedCalendars = await detectSystemCalendars()
        guard !detectedCalendars.isEmpty else { return }

        var subscriptions = subscriptionsSubject.value
        subscriptions.append(contentsOf: detectedCalendars)
        await saveSubscriptions(subscriptions)
        subscriptionsSubject.send(subscriptions)
    }

    private func clearSubscriptionCache(_ subscription: CalendarSubscription) async {
        // 清理相关的事件缓存
        // 清理本地存储的订阅数据
    }

    private func extractSuggestedName(from url: URL) -> String {
        // 从URL中提取建议的名称
        return url.lastPathComponent.replacingOccurrences(of: ".ics", with: "")
    }
}

enum SubscriptionError: LocalizedError {
    case duplicateSubscription
    case subscriptionNotFound
    case systemCalendarNotFound
    case invalidURL(ValidationError?)
    case syncFailed(Error)

    var errorDescription: String? {
        switch self {
        case .duplicateSubscription:
            return "订阅源已存在"
        case .subscriptionNotFound:
            return "找不到指定的订阅源"
        case .systemCalendarNotFound:
            return "找不到指定的系统日历"
        case .invalidURL(let error):
            return "无效的订阅URL: \(error?.localizedDescription ?? "未知错误")"
        case .syncFailed(let error):
            return "同步失败: \(error.localizedDescription)"
        }
    }
}
```

### CalendarEventService Implementation

```swift
class CalendarEventService: CalendarEventServiceProtocol {
    private let subscriptionService: CalendarSubscriptionServiceProtocol
    private let syncService: CalendarSyncServiceProtocol
    private let localStorage: LocalStorageManager

    init(
        subscriptionService: CalendarSubscriptionServiceProtocol,
        syncService: CalendarSyncServiceProtocol,
        localStorage: LocalStorageManager = LocalStorageManager()
    ) {
        self.subscriptionService = subscriptionService
        self.syncService = syncService
        self.localStorage = localStorage
    }

    func getEvents(for date: Date) -> AnyPublisher<[DateEvent], Error> {
        return subscriptionService.getActiveSubscriptions()
            .flatMap { subscriptions in
                Publishers.MergeMany(
                    subscriptions.map { subscription in
                        self.getEvents(for: subscription.id, date: date)
                            .catch { _ in
                                Just([]) // 忽略单个订阅源的错误
                            }
                    }
                )
                .collect()
                .map { eventArrays in
                    eventArrays.flatMap { $0 }
                        .sorted { $0.startDate < $1.startDate }
                }
            }
            .eraseToAnyPublisher()
    }

    func createEvent(_ event: DateEvent) async throws -> DateEvent {
        // 验证事件数据
        if let validationError = DateEvent.validate(
            title: event.title,
            startDate: event.startDate,
            endDate: event.endDate
        ) {
            throw EventError.validationError(validationError)
        }

        // 确保事件有订阅源
        let targetSubscription: CalendarSubscription
        if let subscriptionId = event.subscriptionId {
            let subscriptions = await subscriptionService.getAllSubscriptions().values.first!
            guard let subscription = subscriptions.first(where: { $0.id == subscriptionId }) else {
                throw EventError.subscriptionNotFound
            }
            targetSubscription = subscription
        } else {
            // 创建或使用本地订阅源
            targetSubscription = try await getOrCreateLocalSubscription()
        }

        // 创建EventKit事件
        let eventStore = EKEventStore()
        let ekEvent = EKEvent(eventStore: eventStore)

        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.allDay = event.allDay
        ekEvent.location = event.location
        ekEvent.notes = event.notes
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents

        // 保存到EventKit
        try eventStore.save(ekEvent, span: .thisEvent)

        // 创建本地事件对象
        var createdEvent = event
        createdEvent.eventIdentifier = ekEvent.eventIdentifier
        createdEvent.subscriptionId = targetSubscription.id

        // 保存到本地存储
        try await saveEvent(createdEvent)

        return createdEvent
    }

    // MARK: - Private Methods

    private func getOrCreateLocalSubscription() async throws -> CalendarSubscription {
        let subscriptions = await subscriptionService.getAllSubscriptions().values.first!

        // 查找本地订阅源
        if let localSubscription = subscriptions.first(where: { $0.source == .local }) {
            return localSubscription
        }

        // 创建新的本地订阅源
        let localSubscription = CalendarSubscription(
            name: "本地事件",
            color: .blue,
            source: .local
        )

        try await subscriptionService.addSubscription(localSubscription)
        return localSubscription
    }

    private func saveEvent(_ event: DateEvent) async throws {
        let filename = "events/\(event.date.formatted(.dateTime.year().month().day())).json"

        var existingEvents: [DateEvent] = (try? localStorage.load([DateEvent].self, from: filename)) ?? []
        existingEvents.append(event)

        try localStorage.save(existingEvents, to: filename)
    }
}

enum EventError: LocalizedError {
    case validationError(EventValidationError)
    case subscriptionNotFound
    case eventNotFound
    case permissionDenied
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .validationError(let error):
            return error.localizedDescription
        case .subscriptionNotFound:
            return "找不到指定的订阅源"
        case .eventNotFound:
            return "找不到指定的事件"
        case .permissionDenied:
            return "没有足够的权限执行此操作"
        case .saveFailed(let error):
            return "保存事件失败: \(error.localizedDescription)"
        }
    }
}
```

## Error Handling Strategy

### Error Types Hierarchy

```swift
protocol CalendarServiceError: LocalizedError {
    var errorCode: String { get }
    var recoverySuggestion: String? { get }
    var domain: String { get }
}

// MARK: - Specific Error Types

enum SubscriptionServiceError: CalendarServiceError {
    case duplicateSubscription
    case invalidURL(String)
    case syncTimeout
    case quotaExceeded

    var errorCode: String {
        switch self {
        case .duplicateSubscription: return "SUB_001"
        case .invalidURL: return "SUB_002"
        case .syncTimeout: return "SUB_003"
        case .quotaExceeded: return "SUB_004"
        }
    }

    var domain: String { return "CalendarSubscriptionService" }

    var recoverySuggestion: String? {
        switch self {
        case .duplicateSubscription:
            return "请检查是否已添加相同的订阅源"
        case .invalidURL:
            return "请检查URL格式是否正确"
        case .syncTimeout:
            return "请检查网络连接后重试"
        case .quotaExceeded:
            return "请删除不需要的订阅源后重试"
        }
    }
}

enum EventServiceError: CalendarServiceError {
    case validationFailed(String)
    case creationFailed(String)
    case eventNotFound
    case permissionDenied

    var errorCode: String {
        switch self {
        case .validationFailed: return "EVT_001"
        case .creationFailed: return "EVT_002"
        case .eventNotFound: return "EVT_003"
        case .permissionDenied: return "EVT_004"
        }
    }

    var domain: String { return "CalendarEventService" }

    var recoverySuggestion: String? {
        switch self {
        case .validationFailed:
            return "请检查事件信息是否完整"
        case .creationFailed:
            return "请检查网络连接和权限设置"
        case .eventNotFound:
            return "事件可能已被删除"
        case .permissionDenied:
            return "请在系统设置中允许日历访问权限"
        }
    }
}
```

### Error Recovery Mechanisms

```swift
class ErrorRecoveryManager {
    private let retryQueue = DispatchQueue(label: "error-recovery", qos: .utility)
    private let maxRetries = 3

    func handleServiceError<T>(
        _ error: CalendarServiceError,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: CalendarServiceError = error

        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch let serviceError as CalendarServiceError {
                lastError = serviceError

                // 检查是否可以重试
                guard canRetry(error: serviceError, attempt: attempt) else {
                    throw serviceError
                }

                // 指数退避重试
                let delay = pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError
    }

    private func canRetry(error: CalendarServiceError, attempt: Int) -> Bool {
        guard attempt <= maxRetries else { return false }

        switch error {
        case SubscriptionServiceError.syncTimeout,
             EventServiceError.creationFailed:
            return true
        default:
            return false
        }
    }
}
```

这些服务接口定义了完整的日历事件订阅管理功能，确保了良好的模块化、可测试性和可维护性。每个服务都有明确的职责边界，并通过协议定义了清晰的契约。