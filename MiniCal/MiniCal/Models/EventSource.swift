//
//  EventSource.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

enum EventSource: String, Codable {
    case builtin
    case eventKit
    case user
}
