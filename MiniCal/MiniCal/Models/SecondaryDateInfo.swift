//
//  SecondaryDateInfo.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

struct SecondaryDateInfo: Codable, Equatable {
    let calendarType: CalendarType
    let displayText: String
    let year: Int?
    let month: Int?
    let day: Int?
    let festival: String?
}
