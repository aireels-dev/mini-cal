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

    private let eventStore = EKEventStore()
    private var isAuthorized = false
    private var eventStoreObserver: NSObjectProtocol?
    private let permissionManager = PermissionManager.shared

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            #if os(macOS)
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                isAuthorized = granted
                return granted
            } else {
                // macOS 13 及以下版本使用旧API
                return await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        self.isAuthorized = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
            #else
            return false
            #endif
        } catch {
            Logger.error("Error requesting calendar access", error: error, category: Logger.events)
            isAuthorized = false
            return false
        }
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

        return ekEvents.map { ekEvent in
            CalendarEvent(
                title: ekEvent.title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                source: .eventKit,
                isAllDay: ekEvent.isAllDay
            )
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) async -> [CalendarEvent] {
        guard isAuthorized else {
            Logger.warning("⚠️ EventService not authorized to access calendar", category: Logger.calendar)
            return []
        }

        let enabledCalendars = getEnabledCalendars()

        // 如果没有启用的日历，直接返回空数组
        if let calendars = enabledCalendars, calendars.isEmpty {
            Logger.debug("📅 No enabled calendars, returning empty array", category: Logger.calendar)
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: enabledCalendars)
        let ekEvents = eventStore.events(matching: predicate)
        Logger.debug("📅 EventKit returned \(ekEvents.count) events from \(enabledCalendars?.count ?? 0) calendars", category: Logger.calendar)

        return ekEvents.map { ekEvent in
            CalendarEvent(
                title: ekEvent.title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                source: .eventKit,
                isAllDay: ekEvent.isAllDay
            )
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
