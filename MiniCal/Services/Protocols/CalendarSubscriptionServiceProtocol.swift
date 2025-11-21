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