import Foundation
import EventKit
import Combine
import AppKit

class SystemCalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    private let permissionManager: PermissionManager

    @Published var systemCalendars: [EKCalendar] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(permissionManager: PermissionManager = PermissionManager()) {
        self.permissionManager = permissionManager
    }

    // MARK: - System Calendar Detection
    func detectSystemCalendars() -> AnyPublisher<[EKCalendar], Error> {
        guard permissionManager.isAuthorized else {
            return Fail(error: CalendarError.unauthorized)
                .eraseToAnyPublisher()
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
                    let calendars = try self.eventStore.calendars(for: .event)
                    DispatchQueue.main.async {
                        self.systemCalendars = calendars
                        self.isLoading = false
                        promise(.success(calendars))
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "获取系统日历失败: \(error.localizedDescription)"
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Calendar Subscription Creation
    func createSubscription(for calendar: EKCalendar) -> CalendarSubscription {
        let subscription = CalendarSubscription(
            title: calendar.title,
            color: EventColor(from: calendar.cgColor),
            subscriptionType: .system
        )

        var updatedSubscription = subscription
        updatedSubscription.calendarIdentifier = calendar.calendarIdentifier

        return updatedSubscription
    }

    // MARK: - Calendar Validation
    func validateCalendar(_ calendar: EKCalendar) -> CalendarValidationResult {
        let hasEvents = hasEventsInCalendar(calendar)
        let isAccessible = calendar.allowsContentModifications || !calendar.isImmutable

        return CalendarValidationResult(
            isValid: true,
            hasEvents: hasEvents,
            isAccessible: isAccessible,
            estimatedEventCount: estimateEventCount(for: calendar),
            title: calendar.title,
            source: calendar.source.title
        )
    }

    // MARK: - Event Detection
    private func hasEventsInCalendar(_ ekCalendar: EKCalendar) -> Bool {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [ekCalendar])
        let events = eventStore.events(matching: predicate)

        return !events.isEmpty
    }

    private func estimateEventCount(for ekCalendar: EKCalendar) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 30, to: startDate) ?? startDate

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [ekCalendar])
        let events = eventStore.events(matching: predicate)

        return events.count
    }

    // MARK: - Calendar Information
    func getCalendarInfo(for identifier: String) -> EKCalendar? {
        return eventStore.calendar(withIdentifier: identifier)
    }

    func getAllCalendarSources() -> [EKSource] {
        return eventStore.sources
    }

    // MARK: - Subscription Management
    func createSystemSubscriptions() -> [CalendarSubscription] {
        guard permissionManager.isAuthorized else {
            return []
        }

        return systemCalendars.map { calendar in
            createSubscription(for: calendar)
        }
    }
}

// MARK: - Supporting Types
struct CalendarValidationResult {
    let isValid: Bool
    let hasEvents: Bool
    let isAccessible: Bool
    let estimatedEventCount: Int
    let title: String
    let source: String
}

enum CalendarError: LocalizedError {
    case unauthorized
    case serviceUnavailable
    case calendarNotFound
    case invalidCalendar

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "需要日历访问权限"
        case .serviceUnavailable:
            return "日历服务不可用"
        case .calendarNotFound:
            return "找不到指定的日历"
        case .invalidCalendar:
            return "无效的日历"
        }
    }
}

// MARK: - EventColor Extension
extension EventColor {
    init(from cgColor: CGColor?) {
        guard let cgColor = cgColor else {
            self = .blue
            return
        }

        // 转换为NSColor然后分析
        guard let nsColor = NSColor(cgColor: cgColor) else {
            self = .blue
            return
        }

        // 简化的颜色匹配逻辑 - 使用NSColor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if red > 0.8 && green < 0.3 && blue < 0.3 {
            self = .red
        } else if red > 0.8 && green > 0.5 && blue < 0.3 {
            self = .orange
        } else if red < 0.3 && green < 0.3 && blue > 0.8 {
            self = .blue
        } else if red > 0.5 && green < 0.3 && blue > 0.5 {
            self = .purple
        } else if red < 0.3 && green > 0.8 && blue < 0.3 {
            self = .green
        } else if red > 0.5 && green > 0.5 && blue < 0.3 {
            self = .yellow
        } else if red < 0.3 && green > 0.8 && blue > 0.8 {
            self = .cyan
        } else {
            self = .gray
        }
    }
}