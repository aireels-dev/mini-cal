import Foundation
import EventKit
import Combine

class EventKitService: ObservableObject {
    private let eventStore = EKEventStore()
    private let permissionManager: PermissionManager

    @Published var isLoading = false
    @Published var errorMessage: String?

    init(permissionManager: PermissionManager = PermissionManager()) {
        self.permissionManager = permissionManager
    }

    // MARK: - Event Retrieval
    func getEvents(for date: Date, from calendarId: String) -> AnyPublisher<[CalendarEvent], Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
        }

        guard let ekCalendar = eventStore.calendar(withIdentifier: calendarId) else {
            return Fail(error: CalendarError.calendarNotFound)
                .eraseToAnyPublisher()
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        return getEvents(in: DateRange(startDate: startDate, endDate: endDate), from: [ekCalendar.calendarIdentifier])
    }

    func getEvents(in dateRange: DateRange, from calendarIds: [String]) -> AnyPublisher<[CalendarEvent], Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
        }

        let calendars = calendarIds.compactMap { eventStore.calendar(withIdentifier: $0) }
        guard !calendars.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        isLoading = true
        errorMessage = nil

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(CalendarError.serviceUnavailable))
                return
            }

            DispatchQueue.global(qos: .background).async {
                do {
                    let predicate = self.eventStore.predicateForEvents(
                        withStart: dateRange.startDate,
                        end: dateRange.endDate,
                        calendars: calendars
                    )

                    let ekEvents = self.eventStore.events(matching: predicate)
                    let calendarEvents = ekEvents.map { self.convertEKEventToCalendarEvent($0) }

                    DispatchQueue.main.async {
                        self.isLoading = false
                        promise(.success(calendarEvents))
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "获取事件失败: \(error.localizedDescription)"
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getEvent(identifier: String) -> AnyPublisher<CalendarEvent?, Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(CalendarError.serviceUnavailable))
                return
            }

            DispatchQueue.global(qos: .background).async {
                let ekEvent = self.eventStore.event(withIdentifier: identifier)
                let calendarEvent = ekEvent.map { self.convertEKEventToCalendarEvent($0) }

                DispatchQueue.main.async {
                    promise(.success(calendarEvent))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Event Conversion
    private func convertEKEventToCalendarEvent(_ ekEvent: EKEvent) -> CalendarEvent {
        var event = CalendarEvent(
            title: ekEvent.title,
            startDate: ekEvent.startDate,
            endDate: ekEvent.endDate,
            source: .eventKit
        )

        // 基本属性
        event.isAllDay = ekEvent.isAllDay
        event.location = ekEvent.location
        event.notes = ekEvent.notes
        event.url = ekEvent.url

        // EventKit标识符
        event.eventIdentifier = ekEvent.eventIdentifier

        // 关联信息
        if let calendarId = ekEvent.calendar?.calendarIdentifier {
            event.subscriptionId = self.findSubscriptionId(for: calendarId)
        }

        // 状态和可见性
        event.status = convertEKStatusToEventStatus(ekEvent.status)
        event.visibility = convertEKAvailabilityToEventVisibility(ekEvent.availability)

        // 重复规则
        if let recurrenceRule = ekEvent.recurrenceRules?.first {
            event.recurrenceRule = recurrenceRuleToRRule(recurrenceRule)
        }

        // 参与者
        if let attendees = ekEvent.attendees, !attendees.isEmpty {
            event.attendees = attendees.map { convertEKAttendeeToEventAttendee($0) }
        }

        // 最后修改时间
        event.lastModified = ekEvent.lastModifiedDate

        return event
    }

    private func convertEKStatusToEventStatus(_ ekStatus: EKEventStatus) -> EventStatus {
        switch ekStatus {
        case .confirmed:
            return .confirmed
        case .tentative:
            return .tentative
        case .canceled:
            return .cancelled
        case .none:
            return .confirmed // 默认为确认状态
        @unknown default:
            return .confirmed
        }
    }

    private func convertEKAvailabilityToEventVisibility(_ availability: EKEventAvailability) -> EventVisibility {
        switch availability {
        case .busy:
            return .private
        case .free:
            return .public
        case .tentative:
            return .public
        case .unavailable:
            return .confidential
        @unknown default:
            return .private
        }
    }

    private func convertEKAttendeeToEventAttendee(_ ekParticipant: EKParticipant) -> EventAttendee {
        let attendee = EventAttendee(
            name: ekParticipant.name ?? "未知参与者",
            isOrganizer: ekParticipant.participantRole == .unknown
        )

        var mutableAttendee = attendee
        mutableAttendee.status = convertEKParticipantStatusToAttendeeStatus(ekParticipant.participantStatus)

        return mutableAttendee
    }

    private func convertEKParticipantStatusToAttendeeStatus(_ status: EKParticipantStatus) -> EventAttendee.AttendeeStatus {
        switch status {
        case .unknown:
            return .needsAction
        case .pending:
            return .needsAction
        case .accepted:
            return .accepted
        case .declined:
            return .declined
        case .tentative:
            return .tentative
        case .delegated:
            return .delegated
        case .completed:
            return .accepted
        case .inProcess:
            return .needsAction
        @unknown default:
            return .needsAction
        }
    }

    private func recurrenceRuleToRRule(_ recurrenceRule: EKRecurrenceRule) -> String {
        // 简化的RRULE生成 - 实际实现会更复杂
        var components: [String] = []

        // 频率
        let frequency: String
        switch recurrenceRule.frequency {
        case .daily:
            frequency = "DAILY"
        case .weekly:
            frequency = "WEEKLY"
        case .monthly:
            frequency = "MONTHLY"
        case .yearly:
            frequency = "YEARLY"
        @unknown default:
            frequency = "DAILY"
        }
        components.append("FREQ=\(frequency)")

        // 间隔
        if recurrenceRule.interval > 1 {
            components.append("INTERVAL=\(recurrenceRule.interval)")
        }

        // 结束条件
        if let endDate = recurrenceRule.recurrenceEnd?.endDate {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone.current
            components.append("UNTIL=\(formatter.string(from: endDate))")
        } else if let count = recurrenceRule.recurrenceEnd?.occurrenceCount {
            components.append("COUNT=\(count)")
        }

        return components.joined(separator: ";")
    }

    // MARK: - Helper Methods
    private func findSubscriptionId(for calendarId: String) -> UUID? {
        // 这里应该从存储的订阅中查找对应的UUID
        // 简化实现，实际应该查询LocalStorageManager
        return nil
    }

    // MARK: - Event Statistics
    func getEventStatistics(for calendarId: String, in dateRange: DateRange) -> AnyPublisher<EventStatistics, Error> {
        return getEvents(in: dateRange, from: [calendarId])
            .map { events in
                EventStatistics(
                    totalEvents: events.count,
                    allDayEvents: events.filter { $0.isAllDay }.count,
                    multiDayEvents: events.filter { $0.isMultiDay }.count,
                    pastEvents: events.filter { $0.isPastEvent }.count,
                    currentEvents: events.filter { $0.isCurrentEvent }.count,
                    upcomingEvents: events.filter { !$0.isPastEvent }.count
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types
struct EventStatistics {
    let totalEvents: Int
    let allDayEvents: Int
    let multiDayEvents: Int
    let pastEvents: Int
    let currentEvents: Int
    let upcomingEvents: Int
}