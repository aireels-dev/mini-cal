import Foundation
import Combine

class CalendarEventService: CalendarEventServiceProtocol {

    // MARK: - Local Storage
    private let userDefaults = UserDefaults.standard
    private let localEventsKey = "LocalCalendarEvents"
    private var localEvents: [CalendarEvent] = []
    private let subscriptionService = CalendarSubscriptionService()
    private var cancellables = Set<AnyCancellable>()

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

    // MARK: - Calendar eventFilteringHelper Method

    /// 过滤禁用的订阅事件
    private func filterEnabledEvents(_ events: [CalendarEvent]) async -> [CalendarEvent] {
        // 获取所有订阅
        let subscriptions: [CalendarSubscription]
        do {
            subscriptions = try await subscriptionService.getAllSubscriptions()
        } catch {
            Logger.error("Failed to load subscriptions for filtering: \(error)", category: Logger.calendar)
            return events  // 如果加载失败，返回所有事件（保守策略）
        }

        // 获取所有启用的订阅ID
        let enabledSubscriptionIds = Set(subscriptions.filter { $0.isEnabled }.map { $0.id })

        // 过滤事件：保留没有subscriptionId的事件（本地事件）或属于启用订阅的事件
        return events.filter { event in
            guard let subId = event.subscriptionId else {
                return true  // 本地事件，保留
            }
            return enabledSubscriptionIds.contains(subId)  // 只保留启用订阅的事件
        }
    }

    // MARK: - CalendarEventServiceProtocol Implementation

    func getEvents(for date: Date, from subscriptionIds: [UUID]?) -> AnyPublisher<[CalendarEvent], Error> {
        let calendar = Calendar.current
        var filteredEvents = localEvents.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }

        // 按订阅过滤
        if let subIds = subscriptionIds {
            filteredEvents = filteredEvents.filter { event in
                guard let eventSubId = event.subscriptionId else { return false }
                return subIds.contains(eventSubId)
            }
        }

        return Future { promise in
            Task {
                let enabledEvents = await self.filterEnabledEvents(filteredEvents)
                promise(.success(enabledEvents))
            }
        }
        .eraseToAnyPublisher()
    }

    func getEvents(in dateRange: DateRange, from subscriptionIds: [UUID]?) -> AnyPublisher<[CalendarEvent], Error> {
        var filteredEvents = localEvents.filter { event in
            event.startDate >= dateRange.startDate && event.startDate < dateRange.endDate
        }

        // 按订阅过滤
        if let subIds = subscriptionIds {
            filteredEvents = filteredEvents.filter { event in
                guard let eventSubId = event.subscriptionId else { return false }
                return subIds.contains(eventSubId)
            }
        }

        return Future { promise in
            Task {
                let enabledEvents = await self.filterEnabledEvents(filteredEvents)
                promise(.success(enabledEvents))
            }
        }
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
        let filteredEvents = localEvents.filter { event in
            event.startDate >= dateRange.startDate && event.startDate < dateRange.endDate
        }
        return await filterEnabledEvents(filteredEvents)
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
}