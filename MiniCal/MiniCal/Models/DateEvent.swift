//
//  DateEvent.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct DateEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let date: Date
    let type: EventType
    let color: EventColor
    let description: String?
    let source: EventSource

    init(title: String, date: Date, type: EventType, source: EventSource, description: String? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.type = type
        self.color = type.defaultColor
        self.description = description
        self.source = source
    }
}
