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

    var subscriptionId: UUID?  // 所属组的ID（指向CalendarSubscription或系统日历）
    var eventIdentifier: String?
    var source: EventSource  // 事件类别：系统同步/外部订阅/本地管理

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

    /// 事件来源名称
    var sourceName: String {
        // TODO: 对于外部订阅，从订阅服务获取实际的订阅名称
        return source.displayName
    }

    /// 获取事件显示颜色（从所属组获取）
    func getDisplayColor() -> Color {
        return CalendarGroupService.shared.getColor(for: self)
    }

    init(title: String, startDate: Date, endDate: Date, source: EventSource, isAllDay: Bool = false, eventIdentifier: String? = nil) {
        // 为 EventKit 事件生成稳定的 UUID（基于 eventIdentifier）
        // 其他事件（外部订阅、本地）使用随机 UUID
        if let eventIdentifier = eventIdentifier, !eventIdentifier.isEmpty {
            // 尝试将 eventIdentifier 作为 UUID
            if let uuid = UUID(uuidString: eventIdentifier) {
                self.id = uuid
            } else {
                // 如果不是有效的 UUID 格式，使用 eventIdentifier 的 hash 生成确定性的 UUID
                // 这样相同的 eventIdentifier 总是生成相同的 UUID
                let hash = eventIdentifier.hashValue
                self.id = UUID(
                    uuidString: String(format: "%08X-%04X-%04X-%04X-%012X",
                        (hash >> 0) & 0xFFFFFFFF,
                        (hash >> 32) & 0xFFFF,
                        ((hash >> 32) & 0xFFFF) | 0x4000,  // Version 4
                        ((hash >> 48) & 0x3FFF) | 0x8000,  // Variant
                        (hash >> 16) & 0x0FFFFFFFFFFFFF
                    )
                ) ?? UUID()
            }
        } else {
            // 本地事件：使用随机 UUID
            self.id = UUID()
        }

        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.source = source
        self.isCreatedLocally = (source == .user)
        self.isEditable = (source == .user)
        self.status = .confirmed
        self.visibility = .private

        // 保存 eventIdentifier
        self.eventIdentifier = eventIdentifier
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