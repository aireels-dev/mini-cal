import Foundation
import Combine
import SwiftUI

class EventSubscriptionViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDate: Date?
    @Published var events: [CalendarEvent] = []
    @Published var subscriptions: [CalendarSubscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageManager = LocalStorageManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadSubscriptions()
        setupBindings()
    }

    private func setupBindings() {
        storageManager.$subscriptions
            .receive(on: DispatchQueue.main)
            .assign(to: \.subscriptions, on: self)
            .store(in: &cancellables)
    }

    private func loadSubscriptions() {
        subscriptions = storageManager.loadSubscriptions()
    }

    // MARK: - Date Management
    func selectDate(_ date: Date) {
        selectedDate = date
        loadEvents(for: date)
    }

    func navigateToPreviousMonth() {
        let calendar = Calendar.current
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = previousMonth
        }
    }

    func navigateToNextMonth() {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = nextMonth
        }
    }

    func goToToday() {
        currentDate = Date()
        selectedDate = Date()
        loadEvents(for: Date())
    }

    // MARK: - Event Management
    func loadEvents(for date: Date) {
        guard !subscriptions.isEmpty else {
            events = []
            return
        }

        isLoading = true
        errorMessage = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.events = self.generateMockEvents(for: date)
            self.isLoading = false
        }
    }

    func refreshEvents() {
        guard let selectedDate = selectedDate else {
            loadEvents(for: currentDate)
            return
        }
        loadEvents(for: selectedDate)
    }

    // MARK: - Subscription Management
    func toggleSubscription(_ subscription: CalendarSubscription) {
        var updatedSubscription = subscription
        updatedSubscription.isActive.toggle()
        storageManager.updateSubscription(updatedSubscription)
        refreshEvents()
    }

    func deleteSubscription(_ subscription: CalendarSubscription) {
        storageManager.deleteSubscription(id: subscription.id)
        refreshEvents()
    }

    // MARK: - Mock Data Generation
    private func generateMockEvents(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let activeSubscriptions = subscriptions.filter { $0.isActive }

        return activeSubscriptions.enumerated().compactMap { index, subscription in
            let startDate = calendar.date(byAdding: .hour, value: index * 2 + 9, to: date) ?? date
            let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate

            let event = CalendarEvent(
                title: "\(subscription.title) 事件 \(index + 1)",
                startDate: startDate,
                endDate: endDate,
                source: subscription.subscriptionType == .system ? .eventKit :
                       subscription.subscriptionType == .external ? .builtin : .user
            )

            var mutableEvent = event
            mutableEvent.subscriptionId = subscription.id
            return mutableEvent
        }
    }

    // MARK: - Event Indicators
    func hasEvents(on date: Date) -> Bool {
        return subscriptions.contains { subscription in
            subscription.isActive && shouldShowEventIndicator(for: subscription, on: date)
        }
    }

    func eventIndicators(for date: Date) -> [EventColor] {
        return Array(subscriptions
            .filter { $0.isActive && shouldShowEventIndicator(for: $0, on: date) }
            .map { $0.color }
            .prefix(3))
    }

    private func shouldShowEventIndicator(for subscription: CalendarSubscription, on date: Date) -> Bool {
        return Bool.random()
    }
}

