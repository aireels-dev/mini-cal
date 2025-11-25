import Foundation
import Combine

class CalendarEventService: CalendarEventServiceProtocol {

    // MARK: - Local Storage
    private let userDefaults = UserDefaults.standard
    private let localEventsKey = "LocalCalendarEvents"
    private var localEvents: [CalendarEvent] = []

    init() {
        loadLocalEvents()
    }

    private func loadLocalEvents() {
        guard let data = userDefaults.data(forKey: localEventsKey) else {
            localEvents = []
            return
        }

        do {
            localEvents = try JSONDecoder().decode([CalendarEvent].self, from: data)
            Logger.debug("Loaded \(localEvents.count) local events", category: Logger.calendar)
        } catch {
            Logger.error("Failed to load local events: \(error)", category: Logger.calendar)
            localEvents = []
        }
    }

    private func saveLocalEvents() {
        do {
            let data = try JSONEncoder().encode(localEvents)
            userDefaults.set(data, forKey: localEventsKey)
            Logger.debug("Saved \(localEvents.count) local events", category: Logger.calendar)
        } catch {
            Logger.error("Failed to save local events: \(error)", category: Logger.calendar)
        }
    }

    // MARK: - CalendarEventServiceProtocol Implementation

    func getEvents(for date: Date, from subscriptionIds: [UUID]?) -> AnyPublisher<[CalendarEvent], Error> {
        let calendar = Calendar.current
        let filteredEvents = localEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
        return Just(filteredEvents)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getEvents(in dateRange: DateRange, from subscriptionIds: [UUID]?) -> AnyPublisher<[CalendarEvent], Error> {
        let filteredEvents = localEvents.filter { event in
            event.startDate >= dateRange.startDate && event.startDate < dateRange.endDate
        }
        return Just(filteredEvents)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getEvent(id: UUID) -> AnyPublisher<CalendarEvent?, Error> {
        let event = localEvents.first(where: { $0.id == id })
        return Just(event)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func createEvent(_ event: CalendarEvent) -> AnyPublisher<CalendarEvent, Error> {
        var newEvent = event

        // 确保本地事件的subscriptionId指向本地事件组
        // 如果没有指定组，则使用默认组
        if newEvent.source == .user && newEvent.subscriptionId == nil {
            newEvent.subscriptionId = LocalEventGroupService.shared.defaultGroupId
        }

        localEvents.append(newEvent)
        saveLocalEvents()
        Logger.info("Created local event: \(newEvent.title)", category: Logger.calendar)
        return Just(newEvent)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func updateEvent(_ event: CalendarEvent) -> AnyPublisher<CalendarEvent, Error> {
        if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
            localEvents[index] = event
            saveLocalEvents()
            Logger.info("Updated local event: \(event.title)", category: Logger.calendar)
        }
        return Just(event)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func deleteEvent(id: UUID) -> AnyPublisher<Void, Error> {
        localEvents.removeAll(where: { $0.id == id })
        saveLocalEvents()
        Logger.info("Deleted local event: \(id)", category: Logger.calendar)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func searchEvents(query: String, in dateRange: DateRange?) -> AnyPublisher<[CalendarEvent], Error> {
        // 简化实现，返回空数组
        return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getEventsWithRecurrence(baseEventId: UUID) -> AnyPublisher<[CalendarEvent], Error> {
        // 简化实现，返回空数组
        return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Additional Async Methods

    func getEvents(in dateRange: DateRange) async throws -> [CalendarEvent] {
        return try await withCheckedThrowingContinuation { continuation in
            getEvents(in: dateRange, from: nil)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { events in
                        continuation.resume(returning: events)
                    }
                )
                .store(in: &cancellables)
        }
    }

    func createEvent(_ event: CalendarEvent) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            createEvent(event)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { _ in
                        continuation.resume()
                    }
                )
                .store(in: &cancellables)
        }
    }

    func updateEvent(_ event: CalendarEvent) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            updateEvent(event)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { _ in
                        continuation.resume()
                    }
                )
                .store(in: &cancellables)
        }
    }

    func deleteEvent(_ eventId: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            deleteEvent(id: eventId)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }

    func getAllEvents() async throws -> [CalendarEvent] {
        return try await withCheckedThrowingContinuation { continuation in
            getEvents(in: DateRange(startDate: Date(), endDate: Date().addingTimeInterval(86400)), from: nil)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { events in
                        continuation.resume(returning: events)
                    }
                )
                .store(in: &cancellables)
        }
    }

    private var cancellables = Set<AnyCancellable>()
}