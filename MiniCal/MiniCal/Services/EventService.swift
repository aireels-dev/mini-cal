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

    func fetchEvents(for date: Date) async -> [DateEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { ekEvent in
            DateEvent(
                title: ekEvent.title,
                date: date,
                type: .meeting,
                source: .eventKit,
                description: ekEvent.notes
            )
        }
    }

    func fetchEvents(from startDate: Date, to endDate: Date) async -> [DateEvent] {
        guard isAuthorized else { return [] }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { ekEvent in
            DateEvent(
                title: ekEvent.title,
                date: ekEvent.startDate,
                type: .meeting,
                source: .eventKit,
                description: ekEvent.notes
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
