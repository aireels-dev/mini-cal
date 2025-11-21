import Foundation
import Combine

class EventListViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var filteredEvents: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedDate: Date?
    @Published var dateFilter: DateFilter = .today

    private var cancellables = Set<AnyCancellable>()

    enum DateFilter: String, CaseIterable {
        case today = "今天"
        case week = "本周"
        case month = "本月"
        case all = "全部"

        var dateRange: DateRange? {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                let startOfDay = calendar.startOfDay(for: now)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
                return DateRange(startDate: startOfDay, endDate: endOfDay)

            case .week:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek
                return DateRange(startDate: startOfWeek, endDate: endOfWeek)

            case .month:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let endOfMonth = calendar.date(byAdding: .day, value: 30, to: startOfMonth) ?? startOfMonth
                return DateRange(startDate: startOfMonth, endDate: endOfMonth)

            case .all:
                return nil
            }
        }
    }

    init() {
        setupSearchFilter()
    }

    private func setupSearchFilter() {
        $searchText
            .combineLatest($events, $dateFilter)
            .map { searchText, events, dateFilter in
                var filtered = events

                // 日期过滤
                if let dateRange = dateFilter.dateRange {
                    filtered = filtered.filter { event in
                        dateRange.contains(event.startDate)
                    }
                }

                // 文本搜索过滤
                if !searchText.isEmpty {
                    filtered = filtered.filter { event in
                        event.title.localizedCaseInsensitiveContains(searchText) ||
                        event.location?.localizedCaseInsensitiveContains(searchText) == true ||
                        event.notes?.localizedCaseInsensitiveContains(searchText) == true
                    }
                }

                return filtered.sorted { $0.startDate < $1.startDate }
            }
            .assign(to: \.filteredEvents, on: self)
            .store(in: &cancellables)
    }

    func loadEvents(for date: Date? = nil) {
        selectedDate = date
        isLoading = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.events = self.generateMockEvents(for: date)
            self.isLoading = false
        }
    }

    func refreshEvents() {
        loadEvents(for: selectedDate)
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
    }

    private func generateMockEvents(for date: Date?) -> [CalendarEvent] {
        let calendar = Calendar.current
        let targetDate = date ?? Date()
        var events: [CalendarEvent] = []

        for hour in 9...18 {
            if Bool.random() {
                let startDate = calendar.date(byAdding: .hour, value: hour, to: targetDate) ?? targetDate
                let endDate = calendar.date(byAdding: .minute, value: 30 + Int.random(in: 0...90), to: startDate) ?? startDate

                let eventTypes = EventType.allCases
                let eventType = eventTypes.randomElement() ?? .custom
                let sources = EventSource.allCases
                let source = sources.randomElement() ?? .user

                var event = CalendarEvent(
                    title: "示例事件 - \(eventType.displayName)",
                    startDate: startDate,
                    endDate: endDate,
                    source: source
                )

                event.location = "会议室 \(Int.random(in: 1...10))"
                event.notes = "这是一个示例事件的备注"

                events.append(event)
            }
        }

        return events
    }
}
