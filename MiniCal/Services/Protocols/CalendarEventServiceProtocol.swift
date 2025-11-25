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
