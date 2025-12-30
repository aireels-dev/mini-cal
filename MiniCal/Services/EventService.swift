//
//  EventService.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import EventKit

class EventService {
    static let shared = EventService()

    private let eventStore = EventStoreManager.shared.eventStore
    private var eventStoreObserver: NSObjectProtocol?
    private let permissionManager = PermissionManager.shared

    private init() {}

    /// 获取当前授权状态（直接使用 PermissionManager 的状态）
    private var isAuthorized: Bool {
        return permissionManager.isAuthorized
    }

    /// 请求日历授权（委托给 PermissionManager）
    func requestAuthorization() async -> Bool {
        return await permissionManager.requestEventKitAccess()
    }

    /// 获取启用的日历列表
    private func getEnabledCalendars() -> [EKCalendar]? {
        let allCalendars = eventStore.calendars(for: .event)
        let enabledCalendars = allCalendars.filter { calendar in
            permissionManager.isCalendarEnabled(calendarIdentifier: calendar.calendarIdentifier)
        }

        // 如果没有启用的日历，返回空数组（不加载任何事件）
        // 如果所有日历都启用，返回 nil（EventKit 默认行为，性能更好）
        if enabledCalendars.isEmpty {
            Logger.debug("No enabled calendars, returning empty array", category: Logger.calendar)
            return []
        } else if enabledCalendars.count == allCalendars.count {
            Logger.debug("All calendars enabled, using default behavior (nil)", category: Logger.calendar)
            return nil
        } else {
            Logger.debug("Filtering to \(enabledCalendars.count) enabled calendars", category: Logger.calendar)
            return enabledCalendars
        }
    }

    func fetchEvents(for date: Date) async -> [CalendarEvent] {
        guard isAuthorized else { return [] }

        // 性能监控
        return await PerformanceMonitor.shared.measureAsync("events.fetch.single_day") {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return []
            }

            let enabledCalendars = getEnabledCalendars()

            // 如果没有启用的日历，直接返回空数组
            if let calendars = enabledCalendars, calendars.isEmpty {
                return []
            }

            let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: enabledCalendars)
            let ekEvents = eventStore.events(matching: predicate)

            // 性能优化：使用 ContiguousArray + 预分配容量
            let calendarEvents = ContiguousArray<CalendarEvent>(
                unsafeUninitializedCapacity: ekEvents.count
            ) { buffer, initializedCount in
                    for (index, ekEvent) in ekEvents.enumerated() {
                        buffer[index] = CalendarEvent(
                            title: ekEvent.title,
                            startDate: ekEvent.startDate,
                            endDate: ekEvent.endDate,
                            source: .eventKit,
                            isAllDay: ekEvent.isAllDay,
                            eventIdentifier: ekEvent.eventIdentifier
                        )
                    }
                    initializedCount = ekEvents.count
                }

            return Array(calendarEvents)
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) async -> [CalendarEvent] {
        guard isAuthorized else {
            Logger.warning("⚠️ EventService not authorized (PermissionManager.isAuthorized = \(permissionManager.isAuthorized), status = \(permissionManager.authorizationStatus.rawValue))", category: Logger.calendar)
            return []
        }

        // 性能监控
        return await PerformanceMonitor.shared.measureAsync("events.fetch.range") {
            let enabledCalendars = getEnabledCalendars()

            // 如果没有启用的日历，直接返回空数组
            if let calendars = enabledCalendars, calendars.isEmpty {
                Logger.debug("📅 No enabled calendars, returning empty array", category: Logger.calendar)
                return []
            }

            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: enabledCalendars)
            let ekEvents = eventStore.events(matching: predicate)
            Logger.debug("📅 EventKit returned \(ekEvents.count) events from \(enabledCalendars?.count ?? 0) calendars", category: Logger.calendar)

            // 性能优化：ContiguousArray + 预分配
            let calendarEvents = ContiguousArray<CalendarEvent>(
                unsafeUninitializedCapacity: ekEvents.count
            ) { buffer, initializedCount in
                    for (index, ekEvent) in ekEvents.enumerated() {
                        buffer[index] = CalendarEvent(
                            title: ekEvent.title,
                            startDate: ekEvent.startDate,
                            endDate: ekEvent.endDate,
                            source: .eventKit,
                            isAllDay: ekEvent.isAllDay,
                            eventIdentifier: ekEvent.eventIdentifier
                        )
                    }
                    initializedCount = ekEvents.count
                }

            return Array(calendarEvents)
        }
    }

    /// 批量加载多天事件（按日期分组）- 性能优化版本
    /// 单次 EventKit 查询覆盖整个日期范围，然后按日期分组
    /// - Parameter dateRange: 日期范围
    /// - Returns: 按日期分组的事件字典
    func fetchEventsGrouped(by dateRange: ClosedRange<Date>) async -> [Date: [CalendarEvent]] {
        guard isAuthorized else {
            return [:]
        }

        return await PerformanceMonitor.shared.measureAsync("events.fetch.grouped") {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: dateRange.lowerBound)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: dateRange.upperBound) else {
                return [:]
            }

            let enabledCalendars = getEnabledCalendars()
            if let calendars = enabledCalendars, calendars.isEmpty {
                return [:]
            }

            // 单次查询覆盖整个范围
            let predicate = eventStore.predicateForEvents(
                withStart: startOfDay,
                end: endOfDay,
                calendars: enabledCalendars
            )
            let ekEvents = eventStore.events(matching: predicate)

            // 性能优化：按日期分组（使用字典预分配）
            var groupedEvents: [Date: [CalendarEvent]] = [:]
            groupedEvents.reserveCapacity(ekEvents.count)

            for ekEvent in ekEvents {
                let eventDate = calendar.startOfDay(for: ekEvent.startDate)

                if groupedEvents[eventDate] == nil {
                    groupedEvents[eventDate] = []
                    groupedEvents.reserveCapacity(groupedEvents.count)
                }

                groupedEvents[eventDate]?.append(CalendarEvent(
                    title: ekEvent.title,
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    source: .eventKit,
                    isAllDay: ekEvent.isAllDay,
                    eventIdentifier: ekEvent.eventIdentifier
                ))
            }

            return groupedEvents
        }
    }

    func observeEventStoreChanges(handler: @escaping () -> Void) {
        // 先移除旧的观察者（如果存在）
        if let observer = eventStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // 添加新的观察者并保存
        eventStoreObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            handler()
        }
    }

    deinit {
        // 清理观察者
        if let observer = eventStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
