import Foundation

class ICalParser {

    // MARK: - Parsing Errors

    enum ParseError: Error, LocalizedError {
        case invalidFormat
        case missingRequiredField(String)
        case invalidDate
        case invalidRecurrenceRule
        case encodingError

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "无效的iCalendar格式"
            case .missingRequiredField(let field):
                return "缺少必需字段: \(field)"
            case .invalidDate:
                return "无效的日期格式"
            case .invalidRecurrenceRule:
                return "无效的重复规则"
            case .encodingError:
                return "编码错误"
            }
        }
    }

    // MARK: - Main Parsing Method

    func parse(data: Data, subscriptionId: UUID) throws -> [CalendarEvent] {
        // 尝试不同的编码
        let content = try decodeContent(data)
        let lines = content.components(separatedBy: .newlines)

        var events: [CalendarEvent] = []
        var currentComponent: [String: String] = [:]
        var inEvent = false
        var inCalendar = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: CharacterSet.whitespaces)

            if trimmedLine == "BEGIN:VCALENDAR" {
                inCalendar = true
                continue
            } else if trimmedLine == "END:VCALENDAR" {
                inCalendar = false
                continue
            } else if trimmedLine == "BEGIN:VEVENT" {
                inEvent = true
                currentComponent = [:]
                continue
            } else if trimmedLine == "END:VEVENT" {
                if inEvent {
                    // 处理当前事件
                    if let event = try parseEvent(from: currentComponent, subscriptionId: subscriptionId) {
                        events.append(event)
                    }
                    inEvent = false
                    currentComponent = [:]
                }
                continue
            }

            // 处理属性行
            if inEvent && trimmedLine.contains(":") {
                let components = trimmedLine.split(separator: ":", maxSplits: 1).map { String($0) }
                if components.count == 2 {
                    let fullKey = components[0].trimmingCharacters(in: CharacterSet.whitespaces)
                    let value = components[1].trimmingCharacters(in: CharacterSet.whitespaces)

                    // 提取属性名称（去掉参数部分，如 DTSTART;VALUE=DATE -> DTSTART）
                    let key = fullKey.components(separatedBy: ";").first ?? fullKey

                    currentComponent[key] = value
                }
            }
        }

        return events
    }

    // MARK: - Content Decoding

    private func decodeContent(_ data: Data) throws -> String {
        // 尝试UTF-8编码
        if let content = String(data: data, encoding: .utf8) {
            return content
        }

        // 尝试其他常见编码
        let encodings: [String.Encoding] = [
            .utf8, .utf16, .utf16BigEndian, .utf16LittleEndian,
            .isoLatin1, .macOSRoman, .windowsCP1252
        ]

        for encoding in encodings {
            if let content = String(data: data, encoding: encoding) {
                return content
            }
        }

        throw ParseError.encodingError
    }

    // MARK: - Event Parsing

    private func parseEvent(from properties: [String: String], subscriptionId: UUID) throws -> CalendarEvent? {
        // DTSTART 是必需的，如果没有则跳过此事件
        guard let startDateString = properties["DTSTART"],
              let startDate = try? parseDateTime(startDateString) else {
            print("⚠️ [ICalParser] Skipping event without valid DTSTART")
            return nil
        }

        // UID 检查（可选，但建议有）
        let uid = properties["UID"] ?? UUID().uuidString

        // SUMMARY 是可选的，如果没有则使用默认值
        let summary = properties["SUMMARY"] ?? "无标题事件"

        // DTEND 是可选的，如果没有则使用 DTSTART + 1天（对于全天事件）
        let endDate: Date
        if let endDateString = properties["DTEND"],
           let parsedEndDate = try? parseDateTime(endDateString) {
            endDate = parsedEndDate
        } else if let duration = properties["DURATION"] {
            // 如果有 DURATION 属性，计算结束时间
            endDate = startDate.addingTimeInterval(parseDuration(duration))
        } else {
            // 默认为全天事件，结束时间为第二天 00:00
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        }

        // 解析其他属性
        let location = properties["LOCATION"]
        let description = properties["DESCRIPTION"]
        let url = properties["URL"].flatMap { URL(string: $0) }

        // 解析重复规则
        let recurrenceRule = properties["RRULE"].flatMap { try? parseRecurrenceRule($0) }

        // 解析参与者
        let attendees = try parseAttendees(from: properties)

        // 创建事件
        var event = CalendarEvent(
            title: summary,
            startDate: startDate,
            endDate: endDate,
            source: .external
        )

        // 设置其他属性
        event.location = location
        event.notes = description
        event.url = url
        event.recurrenceRule = recurrenceRule.map { "\($0)" }
        event.attendees = attendees
        event.subscriptionId = subscriptionId

        // 设置是否为全天事件
        event.isAllDay = isAllDayEvent(from: properties)

        return event
    }

    // MARK: - Duration Parsing

    private func parseDuration(_ durationString: String) -> TimeInterval {
        // 简化的 DURATION 解析，格式：P[nD][T[nH][nM][nS]]
        // 例如：P1D = 1天, PT1H = 1小时, P1DT12H = 1天12小时
        var duration: TimeInterval = 0
        let cleaned = durationString.uppercased().trimmingCharacters(in: .whitespaces)

        if cleaned.hasPrefix("P") {
            let components = cleaned.dropFirst() // 去掉 'P'
            let parts = components.split(separator: "T")

            // 解析日期部分
            if let datePart = parts.first {
                if let days = extractNumber(from: String(datePart), suffix: "D") {
                    duration += TimeInterval(days * 24 * 3600)
                }
                if let weeks = extractNumber(from: String(datePart), suffix: "W") {
                    duration += TimeInterval(weeks * 7 * 24 * 3600)
                }
            }

            // 解析时间部分
            if parts.count > 1 {
                let timePart = String(parts[1])
                if let hours = extractNumber(from: timePart, suffix: "H") {
                    duration += TimeInterval(hours * 3600)
                }
                if let minutes = extractNumber(from: timePart, suffix: "M") {
                    duration += TimeInterval(minutes * 60)
                }
                if let seconds = extractNumber(from: timePart, suffix: "S") {
                    duration += TimeInterval(seconds)
                }
            }
        }

        return duration > 0 ? duration : 3600 // 默认 1 小时
    }

    private func extractNumber(from string: String, suffix: String) -> Int? {
        guard string.contains(suffix) else { return nil }
        let numberPart = string.components(separatedBy: suffix).first ?? ""
        return Int(numberPart.filter { $0.isNumber })
    }

    // MARK: - Date Time Parsing

    private func parseDateTime(_ dateString: String?) throws -> Date {
        guard let dateString = dateString else {
            throw ParseError.missingRequiredField("Date")
        }

        // 清理日期字符串，去掉可能的空格
        let cleanedDateString = dateString.trimmingCharacters(in: .whitespaces)

        // 支持多种日期格式：
        // 1. 纯日期：YYYYMMDD (如 19760401)
        // 2. 日期+时间：YYYYMMDDTHHMMSS (如 20250101T120000)
        // 3. UTC时间：YYYYMMDDTHHMMSSZ (如 20250101T120000Z)

        let basicPattern = #"(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2}))?"#
        let timezonePattern = basicPattern + "Z?"

        guard let regex = try? NSRegularExpression(pattern: timezonePattern),
              let match = regex.firstMatch(in: cleanedDateString, options: [], range: NSRange(location: 0, length: cleanedDateString.utf16.count)) else {
            throw ParseError.invalidDate
        }

        let components = match.numberOfRanges > 1 ? (1..<match.numberOfRanges).compactMap { index -> Int? in
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: cleanedDateString) else { return nil }
            return Int(cleanedDateString[swiftRange])
        } : []

        guard components.count >= 3 else {
            throw ParseError.invalidDate
        }

        var dateComponents = DateComponents()
        dateComponents.year = components[0]
        dateComponents.month = components[1]
        dateComponents.day = components[2]

        // 处理时间部分（可选）
        if components.count >= 6 {
            dateComponents.hour = components[3]
            dateComponents.minute = components[4]
            dateComponents.second = components[5]
        } else {
            // 纯日期格式，设置为当天开始时间
            dateComponents.hour = 0
            dateComponents.minute = 0
            dateComponents.second = 0
        }

        // 处理时区
        if cleanedDateString.hasSuffix("Z") {
            // UTC时间
            dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
        } else {
            // 使用系统默认时区
            dateComponents.timeZone = TimeZone.current
        }

        guard let date = Calendar.current.date(from: dateComponents) else {
            throw ParseError.invalidDate
        }

        return date
    }

    // MARK: - Recurrence Rule Parsing

    private func parseRecurrenceRule(_ rruleString: String) throws -> RecurrenceRule {
        // 简化的RRULE解析
        // 格式：FREQ=DAILY;INTERVAL=1;COUNT=10
        let components = rruleString.components(separatedBy: ";")
        var frequency: RecurrenceFrequency = .daily
        var interval: Int = 1
        var count: Int?
        var endDate: Date?

        for component in components {
            let keyValue = component.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: CharacterSet.whitespaces).uppercased()
                let value = keyValue[1].trimmingCharacters(in: CharacterSet.whitespaces)

                switch key {
                case "FREQ":
                    switch value.uppercased() {
                    case "DAILY":
                        frequency = .daily
                    case "WEEKLY":
                        frequency = .weekly
                    case "MONTHLY":
                        frequency = .monthly
                    case "YEARLY":
                        frequency = .yearly
                    default:
                        frequency = .daily
                    }
                case "INTERVAL":
                    interval = Int(value) ?? 1
                case "COUNT":
                    count = Int(value)
                case "UNTIL":
                    endDate = try parseDateTime(value)
                default:
                    break
                }
            }
        }

        return RecurrenceRule(
            frequency: frequency,
            interval: interval,
            count: count,
            endDate: endDate
        )
    }

    // MARK: - Attendee Parsing

    private func parseAttendees(from properties: [String: String]) throws -> [EventAttendee]? {
        var attendees: [EventAttendee] = []
        var attendeeIndex = 0

        // 查找所有ATTENDEE属性
        while true {
            let attendeeKey = attendeeIndex == 0 ? "ATTENDEE" : "ATTENDEE;\(attendeeIndex)"
            guard let attendeeString = properties[attendeeKey] else {
                break
            }

            if let attendee = parseAttendee(attendeeString) {
                attendees.append(attendee)
            }
            attendeeIndex += 1
        }

        return attendees.isEmpty ? nil : attendees
    }

    private func parseAttendee(_ attendeeString: String) -> EventAttendee? {
        // 简化的参与者解析
        // 格式：MAILTO:email@example.com
        guard attendeeString.hasPrefix("MAILTO:") else {
            return nil
        }

        let email = String(attendeeString.dropFirst(7)).trimmingCharacters(in: CharacterSet.whitespaces)
        let name = email.components(separatedBy: "@").first ?? "Unknown"

        var attendee = EventAttendee(name: name)
        attendee.email = email

        return attendee
    }

    // MARK: - Helper Methods

    private func isAllDayEvent(from properties: [String: String]) -> Bool {
        // 检查是否为全天事件
        guard let startDateString = properties["DTSTART"],
              let endDateString = properties["DTEND"] else {
            return false
        }

        // 如果日期格式没有时间部分（没有T），则为全天事件
        return !startDateString.contains("T") && !endDateString.contains("T")
    }

    private func isCurrentEvent(startDate: Date, endDate: Date) -> Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

// MARK: - Supporting Types

struct RecurrenceRule: Codable {
    let frequency: RecurrenceFrequency
    let interval: Int
    let count: Int?
    let endDate: Date?
}

enum RecurrenceFrequency: String, Codable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

