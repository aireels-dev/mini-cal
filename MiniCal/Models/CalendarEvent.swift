import Foundation
import SwiftUI

// MARK: - EventStatus Enum
enum EventStatus: String, Codable, CaseIterable {
    case confirmed = "confirmed"
    case tentative = "tentative"
    case cancelled = "cancelled"
}

// MARK: - EventVisibility Enum
enum EventVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case `private` = "private"
    case confidential = "confidential"
}

// MARK: - CalendarEvent Data Model
struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var location: String?
    var notes: String?
    var url: URL?
    var recurrenceRule: String?
    var attendees: [EventAttendee]?

    var subscriptionId: UUID?
    var eventIdentifier: String?
    var source: EventSource

    var isCreatedLocally: Bool
    var isEditable: Bool
    var lastModified: Date?
    var sequence: Int?

    var status: EventStatus
    var visibility: EventVisibility

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

    var isValid: Bool {
        return !title.isEmpty &&
               startDate <= endDate &&
               (startDate.timeIntervalSince1970 > 0) &&
               (endDate.timeIntervalSince1970 > 0)
    }

    // MARK: - Display Properties

    /// 事件显示颜色 - 从订阅中获取，或使用默认颜色
    var displayColor: Color {
        // 如果事件关联了订阅，从订阅中获取颜色
        // 这里需要通过订阅服务查询，暂时返回默认颜色
        // TODO: 实现从订阅服务获取颜色的逻辑
        return source.defaultColor
    }

    /// 事件来源名称
    var sourceName: String {
        // TODO: 对于外部订阅，从订阅服务获取实际的订阅名称
        return source.displayName
    }

    init(title: String, startDate: Date, endDate: Date, source: EventSource, isAllDay: Bool = false) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.source = source
        self.isCreatedLocally = (source == .user)
        self.isEditable = (source == .user)
        self.status = .confirmed
        self.visibility = .private
    }
}

// MARK: - EventAttendee Data Model
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

    init(name: String, isOrganizer: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isOrganizer = isOrganizer
        self.status = isOrganizer ? .accepted : .needsAction
    }
}

// MARK: - DateRange Helper
struct DateRange: Codable, Hashable {
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