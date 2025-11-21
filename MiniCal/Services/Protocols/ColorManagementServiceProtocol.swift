import Foundation
import Combine

protocol ColorManagementServiceProtocol {
    // 颜色分配
    func assignColor(to subscription: CalendarSubscription, excluding existingColors: [EventColor]) -> EventColor
    func optimizeColorAssignments(for subscriptions: [CalendarSubscription]) -> [ColorConflict]

    // 颜色方案管理
    func getColorSchemes() -> AnyPublisher<[ColorScheme], Error>
    func createColorScheme(_ scheme: ColorScheme) -> AnyPublisher<ColorScheme, Error>
    func updateColorScheme(_ scheme: ColorScheme) -> AnyPublisher<ColorScheme, Error>
    func deleteColorScheme(id: UUID) -> AnyPublisher<Void, Error>

    // 颜色冲突解决
    func resolveColorConflicts(_ conflicts: [ColorConflict]) -> AnyPublisher<[ColorScheme.ColorAssignment], Error>
    func suggestAlternativeColor(for eventType: EventType, excluding colors: [EventColor]) -> EventColor?
}

// MARK: - ColorScheme Data Model
struct ColorScheme: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colors: [ColorAssignment]
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date

    struct ColorAssignment: Codable, Hashable {
        let eventType: EventType
        let color: EventColor
        var isCustom: Bool
    }

    static let builtInSchemes: [ColorScheme] = [
        ColorScheme(
            id: UUID(),
            name: "默认配色",
            colors: EventType.allCases.map {
                ColorAssignment(eventType: $0, color: $0.defaultColor, isCustom: false)
            },
            isBuiltIn: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        ColorScheme(
            id: UUID(),
            name: "高对比度",
            colors: EventType.allCases.enumerated().map { index, type in
                let highContrastColors: [EventColor] = [.red, .blue, .green, .orange, .purple, .yellow]
                let color = highContrastColors[index % highContrastColors.count]
                return ColorAssignment(eventType: type, color: color, isCustom: false)
            },
            isBuiltIn: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]

    func color(for eventType: EventType) -> EventColor? {
        return colors.first { $0.eventType == eventType }?.color
    }

    mutating func setColor(for eventType: EventType, color: EventColor) {
        if let index = colors.firstIndex(where: { $0.eventType == eventType }) {
            colors[index] = ColorAssignment(eventType: eventType, color: color, isCustom: true)
        } else {
            colors.append(ColorAssignment(eventType: eventType, color: color, isCustom: true))
        }
        updatedAt = Date()
    }

    func hasColorConflicts() -> [ColorConflict] {
        var conflicts: [ColorConflict] = []
        let colorGroups = Dictionary(grouping: colors) { $0.color }

        for (color, assignments) in colorGroups where assignments.count > 1 {
            let conflict = ColorConflict(
                color: color,
                eventTypes: assignments.map { $0.eventType },
                severity: assignments.count > 2 ? .high : .medium
            )
            conflicts.append(conflict)
        }

        return conflicts
    }
}

struct ColorConflict: Identifiable, Codable, Hashable {
    let id: UUID
    let color: EventColor
    let eventTypes: [EventType]
    let severity: ConflictSeverity

    init(color: EventColor, eventTypes: [EventType], severity: ConflictSeverity) {
        self.id = UUID()
        self.color = color
        self.eventTypes = eventTypes
        self.severity = severity
    }

    enum ConflictSeverity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}