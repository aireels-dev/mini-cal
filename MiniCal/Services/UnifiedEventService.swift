//
//  UnifiedEventService.swift
//  MiniCal
//
//  统一事件聚合服务 - 整合所有事件源（系统日历、外部订阅、本地事件）
//

import Foundation
import Combine

/// 统一事件服务 - 负责从多个源聚合事件数据
class UnifiedEventService: ObservableObject {
    static let shared = UnifiedEventService()

    // MARK: - Dependencies

    private let systemEventService: EventService
    private let externalEventStorage: ExternalEventStorage
    private let localEventService: CalendarEventService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var lastError: Error?

    // MARK: - Init

    init(
        systemEventService: EventService = EventService.shared,
        externalEventStorage: ExternalEventStorage = ExternalEventStorage.shared,
        localEventService: CalendarEventService = CalendarEventService()
    ) {
        self.systemEventService = systemEventService
        self.externalEventStorage = externalEventStorage
        self.localEventService = localEventService
    }

    // MARK: - Public Methods

    /// 获取指定日期范围内的所有事件（聚合所有源）
    func getEvents(in dateRange: DateRange) async throws -> [CalendarEvent] {
        // 性能监控
        return try await PerformanceMonitor.shared.measureAsync("unified_events.getEvents") {
            isLoading = true
            lastError = nil

            defer {
                isLoading = false
            }

            do {
                // 并发获取所有事件源
                async let systemEvents = systemEventService.fetchEvents(
                    from: dateRange.startDate,
                    to: dateRange.endDate
                )
                async let externalEvents = externalEventStorage.getEvents(in: dateRange)
                async let localEvents = localEventService.getEvents(in: dateRange)

                // 等待所有结果
                let allSystemEvents = await systemEvents
                let allExternalEvents = try await externalEvents
                let allLocalEvents = try await localEvents

                // 合并并去重
                var aggregatedEvents = allSystemEvents + allExternalEvents + allLocalEvents

                // 按事件ID去重（避免重复显示）
                aggregatedEvents = removeDuplicates(from: aggregatedEvents)

                Logger.info("""
                    📊 Event aggregation completed:
                    - System events: \(allSystemEvents.count)
                    - External subscription events: \(allExternalEvents.count)
                    - Local events: \(allLocalEvents.count)
                    - Total (after deduplication): \(aggregatedEvents.count)
                    """, category: Logger.calendar)

                return aggregatedEvents

            } catch {
                lastError = error
                Logger.error("Failed to aggregate events: \(error)", category: Logger.calendar)
                throw error
            }
        }
    }

    /// 获取指定日期的所有事件
    func getEvents(for date: Date) async throws -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        return try await getEvents(in: DateRange(startDate: startOfDay, endDate: endOfDay))
    }

    /// 刷新所有事件源
    func refreshAllSources() async {
        // 触发外部订阅同步（由 CalendarSyncService 负责）
        NotificationCenter.default.post(name: .requestEventRefresh, object: nil)

        Logger.info("Event refresh requested for all sources", category: Logger.calendar)
    }

    // MARK: - Private Methods

    /// 去除重复事件（基于事件ID）
    private func removeDuplicates(from events: [CalendarEvent]) -> [CalendarEvent] {
        var uniqueEvents: [UUID: CalendarEvent] = [:]

        for event in events {
            uniqueEvents[event.id] = event
        }

        return Array(uniqueEvents.values)
    }
}

// MARK: - External Event Storage

/// 外部订阅事件存储服务（持久化外部订阅的事件）
/// 说明：该存储会被多个异步任务并发读写，使用 actor 保证线程安全，避免数据竞争导致的崩溃。
actor ExternalEventStorage {
    static let shared = ExternalEventStorage()

    private let userDefaults = UserDefaults.standard
    private let eventsKey = "ExternalSubscriptionEvents"
    private var cachedEvents: [CalendarEvent] = []

    // MARK: - Init

    init() {
        // 在初始化阶段直接加载缓存，避免在 actor 的非隔离初始化中调用隔离方法
        if let data = userDefaults.data(forKey: eventsKey) {
            do {
                cachedEvents = try JSONDecoder().decode([CalendarEvent].self, from: data)
                Logger.debug("Loaded \(cachedEvents.count) cached external events", category: Logger.calendar)
            } catch {
                Logger.error("Failed to load cached events: \(error)", category: Logger.calendar)
                cachedEvents = []
            }
        } else {
            cachedEvents = []
        }
    }

    // MARK: - Public Methods

    /// 保存外部订阅事件
    func saveEvents(_ events: [CalendarEvent], for subscriptionId: UUID) {
        // 移除该订阅的旧事件
        cachedEvents.removeAll { $0.subscriptionId == subscriptionId }

        // 添加新事件
        cachedEvents.append(contentsOf: events)

        // 持久化
        persistEvents()

        Logger.debug("Saved \(events.count) events for subscription \(subscriptionId)", category: Logger.calendar)
    }

    /// 获取指定日期范围的外部订阅事件
    func getEvents(in dateRange: DateRange) async throws -> [CalendarEvent] {
        let filteredEvents = cachedEvents.filter { event in
            event.startDate >= dateRange.startDate && event.startDate < dateRange.endDate
        }

        // 过滤已禁用的订阅事件
        return try await filterEnabledEvents(filteredEvents)
    }

    /// 清除指定订阅的所有事件
    func clearEvents(for subscriptionId: UUID) {
        cachedEvents.removeAll { $0.subscriptionId == subscriptionId }
        persistEvents()

        Logger.debug("Cleared events for subscription \(subscriptionId)", category: Logger.calendar)
    }

    /// 清除所有外部订阅事件
    func clearAllEvents() {
        cachedEvents.removeAll()
        persistEvents()

        Logger.debug("Cleared all external subscription events", category: Logger.calendar)
    }

    // MARK: - Private Methods

    private func persistEvents() {
        do {
            let data = try JSONEncoder().encode(cachedEvents)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            Logger.error("Failed to persist events: \(error)", category: Logger.calendar)
        }
    }

    /// 过滤已禁用订阅的事件
    private func filterEnabledEvents(_ events: [CalendarEvent]) async throws -> [CalendarEvent] {
        let subscriptionService = CalendarSubscriptionService()
        let subscriptions = try await subscriptionService.getAllSubscriptions()
        let enabledSubscriptionIds = Set(subscriptions.filter { $0.isEnabled }.map { $0.id })

        return events.filter { event in
            guard let subId = event.subscriptionId else { return true }
            return enabledSubscriptionIds.contains(subId)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let requestEventRefresh = Notification.Name("requestEventRefresh")
}
